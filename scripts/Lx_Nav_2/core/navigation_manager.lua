-- Core Navigation Manager

local vec3 = require('common/geometry/vector_3')
local Settings = require('config/settings')
local Logger = require('utils/logger')
local Coordinates = require('utils/coordinates')
local TileManager = require('mesh/tile_manager')
local PolygonExtractor = require('mesh/polygon_extractor')
local GraphBuilder = require('pathfinding/graph_builder')
local AStar = require('pathfinding/astar')
local PathSmoother = require('pathfinding/path_smoother')
local MovementController = require('movement/movement_controller')

local NavigationManager = {}
NavigationManager.__index = NavigationManager

function NavigationManager:new()
    local obj = {
        -- Components
        tile_manager = TileManager:new(),
        graph_builder = GraphBuilder:new(),
        movement_controller = MovementController:new(),
        
        -- State
        current_instance = nil,
        current_position = nil,
        all_polygons = {},
        saved_destination = nil,
        current_path = nil,
        alternative_paths = {},
        extraction = {
            is_running = false,
            job = nil,
            processed = 0,
            total = 0,
            collected = {}
        },
        merge_pending = false,
        rebuild_requested = false,
        
        -- Flags
        is_initialized = false,
        needs_graph_rebuild = false,
        auto_update_enabled = true
    }
    setmetatable(obj, self)
    return obj
end

-- Initialize navigation system
function NavigationManager:start()
    if self.is_initialized then
        Logger:warning("Navigation already initialized")
        return
    end
    
    self.is_initialized = true
    self.auto_update_enabled = true
    
    Logger:info("Navigation system started")
    
    -- Register update callback (same as original Lx_Nav)
    core.register_on_update_callback(function()
        self:update()
    end)
end

-- Stop navigation system
function NavigationManager:stop()
    self.is_initialized = false
    self.auto_update_enabled = false
    self.movement_controller:stop()
    
    Logger:info("Navigation system stopped")
end

-- Main update loop
function NavigationManager:update()
    if not self.is_initialized or not self.auto_update_enabled then
        return
    end
    
    local player = core.object_manager and core.object_manager.get_local_player()
    if not player then return end
    
    local pos = player:get_position()
    if not pos then return end
    
    self.current_position = pos
    
    -- Check instance change
    local instance_id = core.get_instance_id and core.get_instance_id() or 0
    if self.tile_manager:update_instance(instance_id) then
        self:clear_navigation_data()
    end
    
    -- Update tiles
    self:update_tiles(pos)
    
    -- Graph build/extraction orchestration
    if self.graph_builder.is_building then
        self.graph_builder:step_incremental(Settings.get("graph.job_budget_ms"))
        if Settings.get('debug.graph') then
            local p = (self.graph_builder.get_progress and self.graph_builder:get_progress()) or 0
            Logger:debug("Graph build stepping, progress=" .. tostring(math.floor(p * 100)) .. "%")
        end
    elseif self.extraction.is_running then
        self:step_polygon_extraction(Settings.get("tiles.extract_budget_ms") or 1.0)
    elseif self.merge_pending then
        self:finalize_merge_and_start_build()
    else
        -- Debounced rebuild only if tiles changed since last rebuild
        local should_rebuild = false
        local debounce_ms = Settings.get("tiles.rebuild_debounce_ms") or 150
        if (self.tiles_changed_since_rebuild) then
            if (core.cpu_ticks and core.cpu_ticks_per_second) and self._last_tile_load_tick then
                local dt_ticks = core.cpu_ticks() - self._last_tile_load_tick
                local elapsed_ms = (dt_ticks / core.cpu_ticks_per_second()) * 1000.0
                should_rebuild = elapsed_ms >= debounce_ms
            elseif self._last_tile_load_time then
                local elapsed_sec = core.time() - self._last_tile_load_time
                should_rebuild = elapsed_sec >= (debounce_ms / 1000.0)
            end
        end
        if self.rebuild_requested or should_rebuild then
            self.rebuild_requested = false
            if Settings.get('debug.graph') then
                Logger:debug("Starting polygon extraction after debounce")
            end
            self:start_polygon_extraction()
        end
    end
    
    -- Update movement
    self.movement_controller:update()
end

-- Update tile loading
function NavigationManager:update_tiles(position)
    local world_x, world_y = position.x, position.y
    local tile_x, tile_y
    if self.tile_manager.world_to_tile then
        tile_x, tile_y = self.tile_manager:world_to_tile(world_x, world_y)
    else
        tile_x, tile_y = Coordinates.world_to_tile(world_x, world_y)
    end
    
    -- Get instance ID
    local instance_id = (core and core.get_instance_id) and core.get_instance_id() or 0
    
    -- Queue tiles for loading (delta strategy when moving within 1 tile)
    local radius = Settings.get("tiles.load_radius")
    local prev = self._last_tile_center
    local queued
    if prev and (math.abs(prev.x - tile_x) <= 1) and (math.abs(prev.y - tile_y) <= 1) then
        queued = self.tile_manager:queue_tiles_delta(instance_id, prev.x, prev.y, tile_x, tile_y, radius)
    else
        queued = self.tile_manager:queue_tiles_around(instance_id, tile_x, tile_y, radius)
    end
    self._last_tile_center = { x = tile_x, y = tile_y }
    
    -- Process load queue
    if queued > 0 or #self.tile_manager.load_queue > 0 then
        local budget = Settings.get("tiles.load_budget_ms")
        local loaded = self.tile_manager:process_load_queue(budget)
        
        if Settings.get('debug.tiles') then
            Logger:debug("Update tiles: queued=" .. tostring(queued) ..
                         " processed=" .. tostring(loaded) ..
                         " queue_left=" .. tostring(#self.tile_manager.load_queue))
        end
        if loaded > 0 then
            -- Record debounce timestamps
            if core.cpu_ticks and core.cpu_ticks_per_second then
                self._last_tile_load_tick = core.cpu_ticks()
                self._last_tile_load_time = nil
            else
                self._last_tile_load_time = core.time()
                self._last_tile_load_tick = nil
            end
            self.tiles_changed_since_rebuild = true
            if Settings.get('debug.tiles') then
                Logger:debug("Loaded " .. loaded .. " tiles")
            end
        end
    end
    
    -- Evict far tiles
    local keep_radius = Settings.get("tiles.keep_radius")
    self.tile_manager:evict_far_tiles(tile_x, tile_y, keep_radius)
end

-- Start incremental polygon extraction job
function NavigationManager:start_polygon_extraction()
    if self.extraction.is_running then return end
    self.needs_graph_rebuild = false
    local tiles = self.tile_manager:get_loaded_tiles()
    local index = 0
    local tile_count = #tiles
    self.extraction.total = tile_count
    self.extraction.processed = 0
    self.extraction.collected = {}

    local function extraction_co()
        while index < tile_count do
            index = index + 1
            local tile_info = tiles[index]
            if tile_info and tile_info.data then
                local header = tile_info.data.header or nil
                local header_poly_count = header and header.polyCount or -1
                local header_vert_count = header and header.vertCount or -1
                local polygons = tile_info.data.extracted_polygons
                local did_extract_now = false
                if not polygons then
                    polygons = PolygonExtractor.extract_polygons(tile_info.data)
                    if polygons and #polygons > 0 then
                        tile_info.data.extracted_polygons = polygons
                        did_extract_now = true
                    end
                end
                local extracted = (polygons and #polygons or 0)
                if polygons and #polygons > 0 and tile_info.key then
                    self.extraction.collected[tile_info.key] = polygons
                end
                if did_extract_now and (Settings.get('debug.extraction') or Settings.get('debug.merge')) then
                    Logger:debug(
                        "Tile " .. tostring(tile_info.key) ..
                        " headerPolys=" .. tostring(header_poly_count) ..
                        " headerVerts=" .. tostring(header_vert_count) ..
                        " extractedPolys=" .. tostring(extracted)
                    )
                end
            end
            self.extraction.processed = index
            coroutine.yield()
        end
    end

    self.extraction.job = coroutine.create(extraction_co)
    self.extraction.is_running = true
end

-- Step extraction within a time budget (ms)
function NavigationManager:step_polygon_extraction(budget_ms)
    if not self.extraction.is_running then return end
    local start_ms = core.time()
    local start_ticks = (core.cpu_ticks and core.cpu_ticks()) or 0
    local budget = budget_ms or 1.0
    local max_steps = Settings.get('tiles.extract_max_per_step') or 8
    local steps = 0
    local use_ticks = (core.cpu_ticks and core.cpu_ticks_per_second) and true or false
    local end_ticks = nil
    if use_ticks then
        end_ticks = start_ticks + (budget / 1000.0) * core.cpu_ticks_per_second()
    end
    local function within_budget()
        if use_ticks then
            return core.cpu_ticks() < end_ticks
        else
            return (core.time() - start_ms) < budget
        end
    end
    while within_budget() and steps < max_steps do
        if not self.extraction.job or coroutine.status(self.extraction.job) == 'dead' then
            self.extraction.is_running = false
            self.extraction.job = nil
            break
        end
        local ok, err = coroutine.resume(self.extraction.job)
        if not ok then
            Logger:warning("Extraction coroutine error: " .. tostring(err))
            self.extraction.is_running = false
            self.extraction.job = nil
            break
        end
        if coroutine.status(self.extraction.job) == 'dead' then
            self.extraction.is_running = false
            self.extraction.job = nil
            break
        end
        steps = steps + 1
    end

    -- If finished, merge and start graph build
    if not self.extraction.is_running then
        if Settings.get('debug.timing') then
            local ticks_ms = nil
            if core.cpu_ticks and core.cpu_ticks_per_second then
                local elapsed_ticks = core.cpu_ticks() - start_ticks
                ticks_ms = (elapsed_ticks / core.cpu_ticks_per_second()) * 1000.0
            end
            local core_dt = (core.time() - start_ms)
            -- Format helper: show ms nicely; use microseconds for <1ms
            local function fmt_ms(ms)
                if not ms then return "n/a" end
                if ms >= 1.0 then
                    return string.format("%.3f ms", ms)
                else
                    return string.format("%.1f µs", ms * 1000.0)
                end
            end
            local ticks_str = ticks_ms and fmt_ms(ticks_ms) or "n/a"
            local core_ms
            -- If core has coarse resolution (often 0), still report <1 ms
            if core_dt and core_dt > 0 then
                core_ms = core_dt
            else
                core_ms = 0
            end
            local core_str = (core_ms > 0) and fmt_ms(core_ms) or "<1 ms"
            Logger:debug("Extraction step time: ticks=" .. ticks_str .. " core=" .. core_str)
        end
        -- Defer heavy merge/build to next frame to avoid spike
        self.merge_pending = true
    end
end

function NavigationManager:finalize_merge_and_start_build()
    local collected_tiles = 0
    local collected_polys = 0
    for _, polys in pairs(self.extraction.collected or {}) do
        collected_tiles = collected_tiles + 1
        if polys and #polys then collected_polys = collected_polys + #polys end
    end
    if Settings.get('debug.extraction') or Settings.get('debug.merge') then
        Logger:debug("Extraction collected tiles=" .. tostring(collected_tiles) ..
                     " collectedPolys=" .. tostring(collected_polys))
    end
    self.all_polygons = PolygonExtractor.merge_polygons(self.extraction.collected)
    local merged_count = 0
    for _ in pairs(self.all_polygons) do merged_count = merged_count + 1 end
    self.graph_builder:start_incremental_build(self.all_polygons)
    if Settings.get('debug.graph') then
        Logger:debug("Started graph rebuild for mergedPolygons=" .. tostring(merged_count))
    end
    self.merge_pending = false
    -- Reset tile-change flag now that we've kicked a rebuild for this snapshot
    self.tiles_changed_since_rebuild = false
end

-- Rebuild navigation graph
function NavigationManager:rebuild_graph()
    -- Switch to incremental extraction path; flag will be consumed
    self.needs_graph_rebuild = true
    self:start_polygon_extraction()
end

-- Find path to destination
function NavigationManager:find_path(destination)
    if not destination then
        Logger:warning("No destination provided")
        return nil
    end
    
    if not self.current_position then
        Logger:warning("No current position available")
        return nil
    end

    -- Ensure graph is ready
    if self.graph_builder.is_building then
        local progress = (self.graph_builder.get_progress and self.graph_builder:get_progress()) or 0
        Logger:warning("Graph build in progress (" .. tostring(math.floor(progress * 100)) .. "%)")
        return nil
    end
    
    -- Find start and goal polygons
    local start_poly = PolygonExtractor.find_containing_polygon(
        self.current_position, self.all_polygons
    )
    local goal_poly = PolygonExtractor.find_containing_polygon(
        destination, self.all_polygons
    )
    
    if not start_poly or not goal_poly then
        Logger:warning("Could not find polygons for path endpoints")
        return nil
    end

    -- Validate graph nodes exist for endpoints
    local start_node = self.graph_builder:get_node(start_poly.global_id)
    local goal_node = self.graph_builder:get_node(goal_poly.global_id)
    if not start_node or not goal_node then
        Logger:warning("Graph nodes not ready for path endpoints (start=" .. tostring(start_node ~= nil) .. ", goal=" .. tostring(goal_node ~= nil) .. ")")
        -- Attempt to rebuild if polygons exist but nodes are missing
        if self.all_polygons and next(self.all_polygons) ~= nil and not self.graph_builder.is_building then
            Logger:debug("Queueing graph rebuild due to missing nodes")
            self.rebuild_requested = true
        end
        return nil
    end
    
    -- Find polygon path using A*
    local poly_path = AStar.find_path(
        self.graph_builder,
        start_poly.global_id,
        goal_poly.global_id
    )
    
    if not poly_path then
        Logger:warning("No path found")
        return nil
    end
    
    -- Build actual path through polygons
    local path = self:build_path_through_polygons(
        poly_path, self.current_position, destination
    )
    
    -- Smooth the path (log before/after for debugging)
    local in_count = #path
    local method = Settings.get("smoothing.method") or "(none)"
    local smoothing_enabled = Settings.get("smoothing.enabled")
    path = PathSmoother.smooth(path)
    local out_count = path and #path or 0
    Logger:info("[Nav2] Path smoothing: method=" .. tostring(method) .. ", enabled=" .. tostring(smoothing_enabled) .. ", in=" .. tostring(in_count) .. ", out=" .. tostring(out_count))
    
    return path
end

-- Build path through polygon corridor
function NavigationManager:build_path_through_polygons(poly_ids, start_pos, end_pos)
    if not poly_ids or #poly_ids == 0 then
        return nil
    end
    
    local path = {start_pos}
    
    -- Simple portal method: go through polygon centers
    for i = 2, #poly_ids - 1 do
        local poly = self.all_polygons[poly_ids[i]]
        if poly then
            table.insert(path, poly.center)
        end
    end
    
    table.insert(path, end_pos)
    
    return path
end

-- Move to destination
function NavigationManager:move_to(destination, on_finish, on_stuck)
    if not destination then
        Logger:warning("No destination for movement")
        return false
    end
    
    self.saved_destination = destination
    
    -- Find path
    local path = self:find_path(destination)
    if not path then
        Logger:warning("Could not find path to destination")
        return false
    end
    
    self.current_path = path
    
    -- Start movement
    return self.movement_controller:start_path(path, on_finish, on_stuck)
end

-- Stop current movement
function NavigationManager:stop_movement()
    self.movement_controller:stop()
    self.current_path = nil
end

-- Clear navigation data
function NavigationManager:clear_navigation_data()
    self.all_polygons = {}
    self.graph_builder:clear()
    self.current_path = nil
    self.alternative_paths = {}
    self.needs_graph_rebuild = true
    
    Logger:debug("Cleared navigation data")
end

-- Get current path
function NavigationManager:get_current_path()
    return self.current_path
end

-- Get alternative paths
function NavigationManager:get_alternative_paths()
    return self.alternative_paths
end

-- Find K alternative paths
function NavigationManager:find_alternative_paths(destination, k)
    k = k or Settings.get("pathfinding.multi_path_count") or 3
    
    if not destination or not self.current_position then
        return {}
    end
    
    -- Find start and goal polygons
    local start_poly = PolygonExtractor.find_containing_polygon(
        self.current_position, self.all_polygons
    )
    local goal_poly = PolygonExtractor.find_containing_polygon(
        destination, self.all_polygons
    )
    
    if not start_poly or not goal_poly then
        return {}
    end
    
    -- Find K paths
    local poly_paths = AStar.find_k_paths(
        self.graph_builder,
        start_poly.global_id,
        goal_poly.global_id,
        k
    )
    
    local paths = {}
    for _, poly_path in ipairs(poly_paths) do
        local path = self:build_path_through_polygons(
            poly_path, self.current_position, destination
        )
        if path then
            path = PathSmoother.smooth(path)
            table.insert(paths, path)
        end
    end
    
    self.alternative_paths = paths
    return paths
end

-- Check if moving
function NavigationManager:is_moving()
    return self.movement_controller:is_active()
end

-- Get movement progress
function NavigationManager:get_movement_progress()
    return self.movement_controller:get_progress()
end

return NavigationManager