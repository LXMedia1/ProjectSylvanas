-- Navigation Graph Builder

local vec3 = require('common/geometry/vector_3')
local Settings = require('config/settings')
local Logger = require('utils/logger')
local Profiler = require('utils/profiler')

local GraphBuilder = {}
GraphBuilder.__index = GraphBuilder

function GraphBuilder:new()
    local obj = {
        nodes = {},          -- polygon_id -> node data
        edges = {},          -- polygon_id -> list of edges
        job = nil,          -- coroutine for incremental build
        is_building = false,
        build_progress = 0,
        total_polygons = 0,
        dynamic_batch_size = nil
    }
    setmetatable(obj, self)
    return obj
end

-- Build navigation graph from polygons
function GraphBuilder:build(polygons)
    self:clear()
    self.total_polygons = 0
    
    -- Count polygons
    for _ in pairs(polygons) do
        self.total_polygons = self.total_polygons + 1
    end
    
    if self.total_polygons == 0 then
        Logger:debug("No polygons to build graph from")
        return
    end
    
    -- Create nodes
    for poly_id, poly in pairs(polygons) do
        self:_create_node(poly_id, poly)
    end
    
    -- Create edges
    self:_build_edges(polygons)
    
    Logger:info("Built graph with " .. self.total_polygons .. " nodes")
end

-- Start incremental graph build
function GraphBuilder:start_incremental_build(polygons)
    if self.is_building then
        Logger:warning("Graph build already in progress")
        return false
    end
    
    self.is_building = true
    self.build_progress = 0
    
    -- Create coroutine for incremental build
    self.job = coroutine.create(function()
        self:_incremental_build_impl(polygons)
    end)
    
    return true
end

-- Step incremental build with time budget
function GraphBuilder:step_incremental(budget_ms)
    if not self.job or type(self.job) ~= "thread" then
        self.is_building = false
        self.job = nil
        Logger:error("Graph build job invalid; resetting incremental build state")
        return false
    end
    if coroutine.status(self.job) == "dead" then
        self.is_building = false
        return false
    end
    
    -- Optional fast mode to speed up build when user allows
    if Settings.get("graph.fast_mode") then
        budget_ms = math.max(budget_ms or 0.5, 2.0)
    end
    local budget = Profiler.BudgetTracker:new(budget_ms)
    budget:start()
    local steps = 0
    local max_steps = (Settings.get("graph.max_steps_per_frame") or 2)
    
    -- Ensure we make progress even if the time budget rounds to 0
    while (budget:has_budget() or steps == 0) and steps < max_steps do
        if not self.job or type(self.job) ~= "thread" then
            self.is_building = false
            self.job = nil
            return false
        end

        local ok, result = coroutine.resume(self.job)
        if not ok then
            Logger:error("Graph build error: " .. tostring(result))
            self.is_building = false
            self.job = nil
            return false
        end
        
        if not self.job or type(self.job) ~= "thread" then
            self.is_building = false
            self.job = nil
            return false
        end
        
        if coroutine.status(self.job) == "dead" then
            self.is_building = false
            self.job = nil
            if Settings.get('debug.graph') then
                Logger:info("Graph build completed")
            end
            return false
        end
        steps = steps + 1
    end
    
    return true -- Still building
end

-- Implementation of incremental build
function GraphBuilder:_incremental_build_impl(polygons)
    -- Reset structures without touching the active coroutine/job state
    self.nodes = {}
    self.edges = {}
    self.build_progress = 0
    self.total_polygons = 0
    
    -- Count polygons
    local poly_list = {}
    for poly_id, poly in pairs(polygons) do
        -- Validate polygon has minimal structure
        if poly and poly.vertices and #poly.vertices >= 3 and poly.center then
            table.insert(poly_list, {id = poly_id, data = poly})
        end
    end
    self.total_polygons = #poly_list
    
    if self.total_polygons == 0 then
        return
    end
    
    local batch_size = self.dynamic_batch_size or Settings.get("graph.batch_size") or 150
    local processed = 0
    
    -- Create nodes in batches
    for i = 1, #poly_list do
        local item = poly_list[i]
        self:_create_node(item.id, item.data)
        
        processed = processed + 1
        self.build_progress = (processed / self.total_polygons) * 0.5
        
        if processed % batch_size == 0 then
            -- Adjust batch size dynamically to target time per batch
            if Settings.get("graph.target_batch_ms") and core.cpu_ticks and core.cpu_ticks_per_second then
                self._last_batch_ticks = self._last_batch_ticks or core.cpu_ticks()
                local now = core.cpu_ticks()
                local dt_ms = ((now - self._last_batch_ticks) / core.cpu_ticks_per_second()) * 1000.0
                self._last_batch_ticks = now
                local target = Settings.get("graph.target_batch_ms") or 1.5
                local min_b = Settings.get("graph.min_batch") or 50
                local max_b = Settings.get("graph.max_batch") or 300
                if dt_ms > 0 then
                    local factor = target / dt_ms
                    local new_bs = math.floor(math.max(min_b, math.min(max_b, batch_size * factor)))
                    if math.abs(new_bs - batch_size) >= 5 then
                        batch_size = new_bs
                        self.dynamic_batch_size = batch_size
                    end
                end
            end
            coroutine.yield()
        end
    end
    
    -- Build neighbor lookup: tile_key + local index -> global_id
    local lookup = {}
    for id, poly in pairs(polygons) do
        if poly.tile_key and poly.index then
            local bucket = lookup[poly.tile_key]
            if not bucket then
                bucket = {}
                lookup[poly.tile_key] = bucket
            end
            bucket[poly.index] = id
        end
    end

    -- Build edges in batches using lookup (fast same-tile links)
    self:_build_edges_incremental(polygons, batch_size, lookup)
    
    self.build_progress = 1.0
end

-- Build edges incrementally
function GraphBuilder:_build_edges_incremental(polygons, batch_size, lookup)
    local processed = 0
    local total = self.total_polygons
    
    for poly_id, poly in pairs(polygons) do
        if poly and poly.vertices and #poly.vertices >= 3 and poly.center then
            self:_create_edges_for_polygon(poly_id, poly, polygons, lookup)
        end
        
        processed = processed + 1
        self.build_progress = 0.5 + (processed / total) * 0.5
        
        if processed % batch_size == 0 then
            -- Adjust batch size dynamically
            if Settings.get("graph.target_batch_ms") and core.cpu_ticks and core.cpu_ticks_per_second then
                self._last_batch_ticks_e = self._last_batch_ticks_e or core.cpu_ticks()
                local now = core.cpu_ticks()
                local dt_ms = ((now - self._last_batch_ticks_e) / core.cpu_ticks_per_second()) * 1000.0
                self._last_batch_ticks_e = now
                local target = Settings.get("graph.target_batch_ms") or 1.5
                local min_b = Settings.get("graph.min_batch") or 50
                local max_b = Settings.get("graph.max_batch") or 300
                if dt_ms > 0 then
                    local factor = target / dt_ms
                    local new_bs = math.floor(math.max(min_b, math.min(max_b, batch_size * factor)))
                    if math.abs(new_bs - batch_size) >= 5 then
                        batch_size = new_bs
                        self.dynamic_batch_size = batch_size
                    end
                end
            end
            coroutine.yield()
        end
    end
end

-- Create node for polygon
function GraphBuilder:_create_node(poly_id, poly)
    self.nodes[poly_id] = {
        id = poly_id,
        center = poly.center,
        vertices = poly.vertices,
        min_z = poly.min_z,
        max_z = poly.max_z,
        area = poly.area,
        -- Defer clearance calculation to edge creation (cached)
        clearance = nil,
        layer = poly.tile_key and tonumber(poly.tile_key:match("^%d+")) or 0
    }
    self.edges[poly_id] = {}
end

-- Build all edges
function GraphBuilder:_build_edges(polygons)
    for poly_id, poly in pairs(polygons) do
        self:_create_edges_for_polygon(poly_id, poly, polygons)
    end
end

-- Create edges for a single polygon
function GraphBuilder:_create_edges_for_polygon(poly_id, poly, all_polygons, lookup)
    if not poly.neighbors then return end
    
    local edges = {}
    
    for _, neighbor in ipairs(poly.neighbors) do
        -- Fast path: same-tile neighbor via lookup
        if not neighbor.is_external and lookup and poly.tile_key and neighbor.link then
            local bucket = lookup[poly.tile_key]
            if bucket then
                local neighbor_id = bucket[neighbor.link]
                local connected_poly = neighbor_id and all_polygons[neighbor_id] or nil
                if connected_poly then
                    local edge = self:_create_edge(poly, connected_poly)
                    if edge then
                        table.insert(edges, edge)
                    end
                    goto continue
                end
            end
        end
        -- Skip external or unresolved neighbors quickly (avoid O(N^2))
        ::continue::
    end
    
    self.edges[poly_id] = edges
end

-- Find connected polygon through neighbor link
function GraphBuilder:_find_connected_polygon(poly, neighbor, all_polygons)
    -- This is simplified - in reality you'd need to handle cross-tile links
    -- For now, just look for adjacent polygons
    for other_id, other_poly in pairs(all_polygons) do
        if other_id ~= poly.global_id then
            if self:_polygons_adjacent(poly, other_poly) then
                return other_poly
            end
        end
    end
    return nil
end

-- Check if two polygons are adjacent
function GraphBuilder:_polygons_adjacent(poly1, poly2)
    -- Check if polygons share an edge
    local threshold = 0.1
    
    for i = 1, #poly1.vertices do
        local v1 = poly1.vertices[i]
        local v2 = poly1.vertices[(i % #poly1.vertices) + 1]
        
        for j = 1, #poly2.vertices do
            local u1 = poly2.vertices[j]
            local u2 = poly2.vertices[(j % #poly2.vertices) + 1]
            
            -- Check if edges are the same (reversed)
            if (v1:dist_to(u2) < threshold and v2:dist_to(u1) < threshold) then
                return true
            end
        end
    end
    
    return false
end

-- Create edge between polygons
function GraphBuilder:_create_edge(from_poly, to_poly)
    local from_center = from_poly.center
    local to_center = to_poly.center
    
    local distance = from_center:dist_to(to_center)
    
    -- Calculate base cost (ultra-fast mode: distance only)
    local cost = distance
    
    if not Settings.get("graph.ultra_mode") then
        -- Add clearance penalty
        local min_clearance = math.min(
            self:_calculate_clearance(from_poly),
            self:_calculate_clearance(to_poly)
        )
        local clearance_weight = Settings.get("pathfinding.weight_clearance") or 0.25
        if min_clearance < Settings.get("pathfinding.min_clearance") then
            cost = cost * (1 + clearance_weight)
        end
    end
    
    if not Settings.get("graph.ultra_mode") then
        -- Add layer change penalty
        local layer_weight = Settings.get("pathfinding.weight_layer") or 2.0
        if from_poly.tile_key ~= to_poly.tile_key then
            local z_diff = math.abs(from_center.z - to_center.z)
            if z_diff > 2 then
                cost = cost * (1 + layer_weight * (z_diff / 10))
            end
        end
    end
    
    return {
        to = to_poly.global_id,
        cost = cost,
        distance = distance
    }
end

-- Calculate polygon clearance (distance to nearest edge)
function GraphBuilder:_calculate_clearance(poly)
    if poly._clearance ~= nil then
        return poly._clearance
    end
    if not poly.vertices or #poly.vertices < 3 then
        poly._clearance = 0
        return 0
    end
    local min_dist = math.huge
    local center = poly.center
    for i = 1, #poly.vertices do
        local v1 = poly.vertices[i]
        local v2 = poly.vertices[(i % #poly.vertices) + 1]
        local dist = self:_point_to_line_distance(center, v1, v2)
        if dist < min_dist then min_dist = dist end
    end
    poly._clearance = min_dist
    return min_dist
end

-- Calculate distance from point to line segment
function GraphBuilder:_point_to_line_distance(point, line_start, line_end)
    local line = line_end - line_start
    local len_sq = line:dot(line)
    
    if len_sq < 0.0001 then
        return point:dist_to(line_start)
    end
    
    local t = math.max(0, math.min(1, (point - line_start):dot(line) / len_sq))
    local projection = line_start + line * t
    
    return point:dist_to(projection)
end

-- Get node by polygon ID
function GraphBuilder:get_node(poly_id)
    return self.nodes[poly_id]
end

-- Get edges for polygon
function GraphBuilder:get_edges(poly_id)
    return self.edges[poly_id] or {}
end

-- Clear graph
function GraphBuilder:clear()
    self.nodes = {}
    self.edges = {}
    self.job = nil
    self.is_building = false
    self.build_progress = 0
    self.total_polygons = 0
end

-- Get build progress (0-1)
function GraphBuilder:get_progress()
    return self.build_progress
end

return GraphBuilder