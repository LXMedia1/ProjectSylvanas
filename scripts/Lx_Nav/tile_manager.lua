-- Binary reading helpers are no longer needed here; decoding is centralized in mmap_decode

-- Convert Recast (x,y,z) to game (x,y,z)
-- User specified: x_game = z_mesh, y_game = x_mesh, z_game = y_mesh
local function toGameCoordinates(nx, ny, nz)
    return nz, nx, ny
end
-- Debug logging helper
local function dlog(self, msg)
    if self and self.debuglog_enabled then core.log(msg) end
end

-- MeshParser now delegates to mmap_decode for all binary parsing
local MMap = require('mmap_decode')
local MeshParser = {}
function MeshParser.parse_tile(data)
	return MMap.parse_tile(data)
end

function MeshParser.parse_tile_file(filename)
	return MMap.parse_tile_file(filename)
end

    -- Parsing moved to mmap_decode; no local implementation here

-- Legacy raw parsing helpers removed (parsing now handled in mmap_decode.lua)

-- Extract polygons moved to MMap.extract_polygons

local mesh_helper = require('mesh_helper')

-- Function to convert binary data to hex string
local function to_hex_string(data)
    local hex = ""
    for i = 1, #data do
        hex = hex .. string.format("%02X ", string.byte(data, i))
        -- Add newline every 16 bytes for readability
        if i % 16 == 0 then
            hex = hex .. "\n"
        end
    end
    return hex
end

-- Profiling helpers using CPU ticks (preferred for accuracy)
local function ticks_to_ms(ticks)
    local hz = core.cpu_ticks_per_second and core.cpu_ticks_per_second() or 0
    if not hz or hz <= 0 then return 0.0 end
    return (ticks * 1000.0) / hz
end

-- Forward declaration for path straightening helper
local visibility_straighten

local TileManager = {}
function TileManager:new()
    local obj = {
        current_tile = nil,
        previous_tile = nil,
        debug_enabled = false,         -- Disabled by default for API usage
        enhanced_visualization = false,
        draw_polygons = false,
        draw_navmesh_enabled = false,  -- Master toggle for mesh drawing (default disabled)
        -- Path smoothing options
        smooth_path_enabled = true,
        smooth_iterations = 3,
        simplify_tolerance = 3.0,
        -- Tile loading
        tile_load_radius = 2,
        -- Keep tiles within this Chebyshev radius; tiles farther than this are evicted
        -- Set > tile_load_radius to avoid thrashing on tile boundary oscillation
        tile_keep_radius = 3,
        -- Async graph build budget (ms per frame)
        job_time_budget_ms = 0.5,
        tile_load_budget_ms = 2.0,
        graph_batch_size = 150,
        graph_target_batch_ms = 1.5,
        graph_min_batch = 50,
        graph_max_batch = 300,
        -- Navmesh (debug draw) incremental build
        navmesh_job = nil,
        navmesh_job_budget_ms = 1.5,
        -- Coroutine for incremental graph build
        graph_job = nil,
        -- Path cost preferences
        min_clearance = 1.5,
        weight_clearance = 0.25,
        -- Prefer staying on the same vertical layer (bridges vs ground)
        weight_layer = 2.0,
        -- Multi-path planning
        alt_paths_nodes = nil,        -- array of alternative paths (each is array of vec3)
        -- Simplified cost model
        last_auto_recompute_ms = 0,
        -- Pathfinding state
        saved_position = nil,
        path_nodes = nil,              -- Array of vec3 along computed path
        loaded_tiles = {},             -- map "x:y" -> true
        tiles = {},                    -- map "x:y" -> { tile_data = ..., polygons = ... }
        tile_parse_cache = {},         -- filename -> parsed tile_data (or false if missing)
        all_polygons = {},             -- merged polygons across loaded tiles
        poly_lookup = {},              -- nodeId -> polygon for path rendering
        graph = { nodes = {}, edges = {} }, -- nodes: {id, center, v1,v2,v3}; edges: id -> {neighbor_ids}
        edge_index = {} ,              -- normalized edge key -> node id (for adjacency build)
        center_navmesh_key = nil,      -- which tile key the current navmesh represents
        -- Active world identifier (to reset mesh when changing instance/continent)
        active_instance_id = nil,
        tiles_dirty = false,           -- whether merged graph needs rebuild
        -- Build/versioning
        graph_build_id = 0,            -- increments when a merged graph build completes
        path_graph_id = nil,           -- graph id the current path was computed against
        -- Profiling configuration
        profile_enabled = true,
        profile_threshold_ms = 2.0,    -- only log sections slower than this
        profile_log_each_tile = false, -- set true to log every tile load timing
        -- Movement state
        move_active = false,
        move_index = 2,                -- first path node is current position
        move_reach_radius = 1.4,
        forward_active = false,
        last_forward_toggle_ms = 0,
        desired_alignment_threshold = 0.85,
        debug_movement_log_interval_ms = 1000,
        last_movement_log_ms = 0,
        forward_restart_delay_ms = 120,
        turn_left_active = false,
        turn_right_active = false,
        use_look_at = false,           -- disabled by default to showcase key-turn steering
        -- Hybrid steering assistance (brief look_at pulses when wiggling/misaligned)
        assist_look_at_enabled = true,
        look_at_pulse_ms = 80,
        look_at_budget_ms_per_sec = 150,
        look_at_budget_window_start_ms = 0,
        look_at_budget_used_ms = 0,
        look_at_pulse_until_ms = 0,
        wiggle_switch_window_ms = 800,
        wiggle_switch_count = 0,
        last_wiggle_reset_ms = 0,
        last_turn_state = 0,           -- -1 right, 0 none, 1 left
        last_bad_align_start_ms = 0,
        angle_tolerance = 0.06,       -- ~3.4 degrees
        hard_turn_threshold = 1.2,    -- rad; pause forward on sharp turns
        move_finish_cb = nil,         -- optional callback when movement completes
        -- API flags
        show_path = false,
        debuglog_enabled = false,
        debug_tile_boundaries = {},
        debug_vertices = {},
        debug_texts = {},
        -- Visualization control (disable in production)
        allow_visualization = false
        ,
        -- Detour-strict behavior: funnel-only, no extra smoothing
        strict_detour_mode = false
        ,
        -- Corner rounding inside corridor for natural turns
        round_corners_enabled = true,
        min_turn_radius = 2.8,
        round_steps = 4
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

-- Disable drawing of alternative paths and provide a cleanup helper
function TileManager:clear_alt_paths()
    self.alt_paths_nodes = nil
end

function TileManager:format_tile_filename(continent_id, tile_x, tile_y)
    -- Format the filename as ididxxyy.mmtile (continent_id, tile_x, tile_y)
    local id_str = string.format("%04d", continent_id)
    local x_str = string.format("%02d", tile_x)
    local y_str = string.format("%02d", tile_y)
    return "mmaps/" .. id_str .. x_str .. y_str .. ".mmtile"
end

function TileManager:start()
    -- Defensive: clear any stuck inputs on startup (e.g., after reloads)
    self:release_all_inputs()

    core.register_on_update_callback(function()
        -- Detect instance change and reset meshes to avoid cross-continent memory bloat
        local cur_instance = core.get_instance_id and core.get_instance_id() or nil
        if self.active_instance_id == nil and cur_instance ~= nil then self.active_instance_id = cur_instance end
        if (cur_instance ~= nil and self.active_instance_id ~= nil and cur_instance ~= self.active_instance_id) then
            self:reset_for_new_area(cur_instance)
        end
        local player = core.object_manager.get_local_player()
        if player and player:is_valid() then
            local pos = player:get_position()
            self:update(pos)

            -- Auto-recompute path if settings changed (paused while moving)
            if (not self.move_active) and self.saved_position and self.path_nodes then
                local now = core.time() or 0
                if now - (self.last_auto_recompute_ms or 0) > 200 then
                    self:compute_path_to_saved()
                    self.last_auto_recompute_ms = now
                end
            end
            -- Drive movement along guidance/path if active; otherwise ensure inputs are released
            if self.move_active then
                self:update_movement()
            else
                if self.forward_active or self.turn_left_active or self.turn_right_active then
                    dlog(self, "Idle state detected with inputs active; releasing")
                    self:release_all_inputs()
                end
            end
        end
        -- Continue incremental graph building within a small time budget
        self:step_graph_job_with_budget()
        -- If a target exists but no path yet, try computing once graph is ready and builder is idle
        if (not self.move_active) and self.saved_position and (not self.path_nodes or #self.path_nodes < 2) then
            local graph_ready = self.graph and self.graph.nodes and next(self.graph.nodes) ~= nil
            local build_idle = (not self.graph_job) or (coroutine.status(self.graph_job) == "dead")
            if graph_ready and build_idle then
                self:compute_path_to_saved()
            end
        end
    end)

    -- Register render callback
    core.register_on_render_callback(function()
        -- Always allow path overlay when requested, independent of debug visualization
        local now_ms = core.time() or 0
        local force_draw = self.path_draw_until_ms and now_ms < self.path_draw_until_ms
        if self.show_path or force_draw then
            self:draw_path()
        end
        -- Gated debug/mesh visualization
        if not self.allow_visualization then return end
        if self.debug_enabled then
            self:draw_navmesh()
            if self.draw_path_polygons_enabled then
                self:draw_path_polygons()
            end
        end
    end)

    -- Register menu render callback
    -- Menu is disabled for API usage; consumers can toggle flags via the API

    dlog(self, "TileManager started.")
end

function TileManager:update(pos)
    local tile_x, tile_y = mesh_helper.get_tile_coordinates(pos.x, pos.y)
    local new_tile = { x = tile_x, y = tile_y }

    if not self.current_tile or new_tile.x ~= self.current_tile.x or new_tile.y ~= self.current_tile.y then
        dlog(self, "Tile changed to: " .. tile_x .. ", " .. tile_y)
        self.previous_tile = self.current_tile
        self.current_tile = new_tile
        -- Debounce small oscillations across the seam; only rebuild if center changed and enough time passed
        local now = core.time() or 0
        if not self._last_tile_change_ms or (now - self._last_tile_change_ms) > 300 then
            self.tiles_dirty = true
            self._last_tile_change_ms = now
        end
    end

    -- Always make sure a symmetric neighborhood is loaded and graph is merged
    local changed = self:ensure_neighbor_tiles_loaded(tile_x, tile_y, self.tile_load_radius or 2)
    -- Evict far-away tiles conservatively to avoid thrashing at boundaries
    self:evict_far_tiles(tile_x, tile_y, self.tile_keep_radius or 3)
    -- On initial startup, self.current_tile is nil; force a first-time graph build once center is loaded
    if changed or self.tiles_dirty or (self.graph and (not next(self.graph.nodes))) then
        self:schedule_incremental_graph_build()
        self.tiles_dirty = false
    end
end

-- Reset all loaded mesh and path state on area switch (instance/map change)
function TileManager:reset_for_new_area(new_instance_id)
    self:stop_movement()
    self:release_all_inputs()
    self.loaded_tiles = {}
    self.tiles = {}
    self.all_polygons = {}
    self.poly_lookup = {}
    self.graph = { nodes = {}, edges = {} }
    self.edge_index = {}
    self.center_navmesh_key = nil
    self.current_tile = nil
    self.previous_tile = nil
    self.path_nodes = nil
    self.path_poly_ids = nil
    self.saved_position = nil
    self.graph_job = nil
    self.tiles_dirty = true
    self.active_instance_id = new_instance_id
    core.log("[Nav] Area changed (instance_id=" .. tostring(new_instance_id) .. ") — cleared cached meshes and paths")
end

-- Ensure tiles exist around a center tile (radius in tile units) and keep convenience pointers
function TileManager:ensure_neighbor_tiles_loaded(cx, cy, radius, budget_ms_override)
    local continent_id = core.get_instance_id()
    local r = math.max(0, math.floor(radius or 0))
    local any_loaded = false
    local call_t0 = core.cpu_ticks and core.cpu_ticks() or 0
    local budget_ms = budget_ms_override
        and math.max(0, budget_ms_override)
        or (self.tile_load_budget_ms or 2.0)
    local hz = core.cpu_ticks_per_second and core.cpu_ticks_per_second() or 0
    local budget_ticks = (hz and hz > 0) and (budget_ms * hz / 1000.0) or 0
    -- Always try to load the center tile first (no budget gating) so initial graph builds without movement
    local center_key = tostring(cx) .. ":" .. tostring(cy)
    if not self.loaded_tiles[center_key] then
        local filename = self:format_tile_filename(continent_id, cx, cy)
        local parsed, polys, timings = MMap.get_tile_with_polygons(filename, toGameCoordinates, "xform-game")
        if parsed and polys then
            self.tiles[center_key] = { tile_data = parsed, polygons = polys }
            self.loaded_tiles[center_key] = true
            any_loaded = true
            if self.profile_enabled and (self.profile_log_each_tile or (timings.read_ms or 0) > self.profile_threshold_ms or (timings.parse_ms or 0) > self.profile_threshold_ms or (timings.extract_ms or 0) > self.profile_threshold_ms) then
                core.log(string.format("[Perf] tile %s read=%.2fms parse=%.2fms extract=%.2fms verts=%d polys=%d", filename, timings.read_ms or 0, timings.parse_ms or 0, timings.extract_ms or 0, parsed.vertCount or -1, (polys and #polys or 0)))
            end
        else
            core.log_warning("Failed to load tile or polygons: " .. filename)
        end
    end
    for dx = -r, r do
        for dy = -r, r do
            if budget_ticks > 0 then
                local now_ticks = core.cpu_ticks and core.cpu_ticks() or 0
                if (now_ticks - call_t0) >= budget_ticks then
                    -- Time-slice tile loading; finish remaining tiles in subsequent frames
                    return any_loaded
                end
            end
            local tx, ty = cx + dx, cy + dy
            if tx >= 0 and tx <= 63 and ty >= 0 and ty <= 63 then
                local key = tostring(tx) .. ":" .. tostring(ty)
                if not self.loaded_tiles[key] then
                    local filename = self:format_tile_filename(continent_id, tx, ty)
                    dlog(self, string.format("[Nav] Loading tile %d:%d -> %s", tx, ty, filename))
                    local parsed2, polys2, timings2 = MMap.get_tile_with_polygons(filename, toGameCoordinates, "xform-game")
                    if parsed2 and polys2 then
                        self.tiles[key] = { tile_data = parsed2, polygons = polys2 }
                        self.loaded_tiles[key] = true
                        any_loaded = true
                        dlog(self, string.format("[Nav] Loaded %s verts=%d polys=%d (read=%.2fms parse=%.2fms extract=%.2fms)", filename, parsed2.vertCount or -1, (polys2 and #polys2 or 0), timings2.read_ms or 0, timings2.parse_ms or 0, timings2.extract_ms or 0))
                        if self.profile_enabled and (self.profile_log_each_tile or (timings2.read_ms or 0) > self.profile_threshold_ms or (timings2.parse_ms or 0) > self.profile_threshold_ms or (timings2.extract_ms or 0) > self.profile_threshold_ms) then
                            core.log(string.format("[Perf] tile %s read=%.2fms parse=%.2fms extract=%.2fms verts=%d polys=%d", filename, timings2.read_ms or 0, timings2.parse_ms or 0, timings2.extract_ms or 0, parsed2.vertCount or -1, (polys2 and #polys2 or 0)))
                        end
                    else
                        if self.debuglog_enabled then
                            core.log_warning("[Nav] Missing or empty tile file: " .. filename)
                        end
                    end
                end
            end
        end
    end
    local ckey = tostring(cx) .. ":" .. tostring(cy)
    local cent = self.tiles[ckey]
    if cent then
        self.current_tile_data = cent.tile_data
        self.current_polygons = cent.polygons
        -- Only regenerate center navmesh if the center tile changed
        if self.center_navmesh_key ~= ckey then
            if self.allow_visualization and (self.debug_enabled or self.draw_navmesh_enabled) then
                -- Start incremental navmesh build job
                self.navmesh = { vertices = {}, triangles = {} }
                local tile = cent.tile_data
                local polys = tile.polys or {}
                local detail_tris = tile.detailTris or {}
                local detail_meshes = tile.detailMeshes or {}
                local base_vertices = {}
                for i = 0, tile.vertCount - 1 do
                    local x = tile.vertices[i * 3 + 1]
                    local y = tile.vertices[i * 3 + 2]
                    local z = tile.vertices[i * 3 + 3]
                    local gx, gy, gz = toGameCoordinates(x, y, z)
                    base_vertices[i] = { x = gx, y = gy, z = gz }
                end
                local detail_vertices = {}
                for i = 1, tile.detailVertCount do
                    local x, y, z = tile.getDetailVertWorld(i)
                    local gx, gy, gz = toGameCoordinates(x, y, z)
                    detail_vertices[i - 1] = { x = gx, y = gy, z = gz }
                end
                local tri_idx = 1
                self.navmesh_job = coroutine.create(function()
                    local hz = core.cpu_ticks_per_second and core.cpu_ticks_per_second() or 0
                    local budget_ticks = (self.navmesh_job_budget_ms or 3.0) * (hz > 0 and hz or 1) / 1000.0
                    local start_ticks = core.cpu_ticks and core.cpu_ticks() or 0
                    local triangles_added, triangles_skipped = 0, 0
                    while tri_idx <= #polys do
                        local poly = polys[tri_idx]
                        local dmesh = detail_meshes[tri_idx]
                        if dmesh then
                            local triBase_masked = dmesh.triBase % 1048576
                            local vertBase_masked = dmesh.vertBase % 1048576
                            if triBase_masked < #detail_tris then
                                for t = 0, dmesh.triCount - 1 do
                                    local tri_i = triBase_masked + t + 1
                                    if tri_i <= #detail_tris then
                                        local tri = detail_tris[tri_i]
                                        local tri_vertices = {}
                                        for _, idx in ipairs{ tri.vertIndex0, tri.vertIndex1, tri.vertIndex2 } do
                                            local vertex
                                            if idx < poly.vertCount then
                                                local base_vert_idx = poly.verts[idx + 1]
                                                vertex = base_vertices[base_vert_idx]
                                            else
                                                local detail_vert_idx = vertBase_masked + (idx - poly.vertCount)
                                                vertex = detail_vertices[detail_vert_idx]
                                            end
                                            if vertex then
                                                local vi = #self.navmesh.vertices + 1
                                                self.navmesh.vertices[vi] = vertex
                                                table.insert(tri_vertices, vi)
                                            end
                                        end
                                        if #tri_vertices == 3 then
                                            local v1 = self.navmesh.vertices[tri_vertices[1]]
                                            local v2 = self.navmesh.vertices[tri_vertices[2]]
                                            local v3 = self.navmesh.vertices[tri_vertices[3]]
                                            if v1 and v2 and v3 then
                                                local d1 = math.sqrt((v2.x-v1.x)^2 + (v2.y-v1.y)^2 + (v2.z-v1.z)^2)
                                                local d2 = math.sqrt((v3.x-v2.x)^2 + (v3.y-v2.y)^2 + (v3.z-v2.z)^2)
                                                local d3 = math.sqrt((v1.x-v3.x)^2 + (v1.y-v3.y)^2 + (v1.z-v3.z)^2)
                                                local max_edge = math.max(d1, d2, d3)
                                                if max_edge <= 50.0 then
                                                    table.insert(self.navmesh.triangles, tri_vertices)
                                                    triangles_added = triangles_added + 1
                                                else
                                                    triangles_skipped = triangles_skipped + 1
                                                end
                                            end
                                        end
                                    end
                                    if (core.cpu_ticks() - start_ticks) >= budget_ticks then
                                        coroutine.yield()
                                        start_ticks = core.cpu_ticks()
                                    end
                                end
                            end
                        end
                        tri_idx = tri_idx + 1
                    end
                end)
            else
                self.navmesh = nil
            end
            self.center_navmesh_key = ckey
        end
    end
    local call_t1 = core.cpu_ticks and core.cpu_ticks() or 0
    local total_ms = ticks_to_ms((call_t1 or 0) - (call_t0 or 0))
    if self.profile_enabled and total_ms > (self.profile_threshold_ms * 2) then
        core.log(string.format("[Perf] ensure_neighbor_tiles_loaded center=%s total=%.2fms", ckey, total_ms))
    end
    return any_loaded
end

-- Unload tiles that are outside a keep radius (Chebyshev distance) from center tile
function TileManager:evict_far_tiles(cx, cy, keep_radius)
    local r = math.max(0, math.floor(keep_radius or 2))
    if r < 0 then r = 0 end
    if not self.loaded_tiles then return end
    local removed_any = false
    -- Collect keys first to avoid mutating during iteration semantics
    local to_remove = {}
    for key, _ in pairs(self.loaded_tiles) do
        local sep = string.find(key, ":", 1, true)
        if sep then
            local tx = tonumber(string.sub(key, 1, sep - 1)) or 0
            local ty = tonumber(string.sub(key, sep + 1)) or 0
            local dx = math.abs(tx - cx)
            local dy = math.abs(ty - cy)
            local far_from_current = (dx > r) or (dy > r)
            local far_from_previous = true
            if self.previous_tile then
                local px, py = self.previous_tile.x, self.previous_tile.y
                local dxp = math.abs(tx - px)
                local dyp = math.abs(ty - py)
                far_from_previous = (dxp > r) or (dyp > r)
            end
            -- Evict only if far from BOTH current and previous centers to reduce thrash at seams
            if far_from_current and far_from_previous then
                table.insert(to_remove, key)
            end
        end
    end
    -- Debug log summary before removal
    if self.debuglog_enabled and #to_remove > 0 then
        local preview = {}
        local max_list = math.min(5, #to_remove)
        for i = 1, max_list do preview[i] = to_remove[i] end
        dlog(self, string.format("[Nav] Evicting %d tile(s) beyond r=%d from center %d:%d (e.g. %s)", #to_remove, r, cx, cy, table.concat(preview, ",")))
    end
    for i = 1, #to_remove do
        local k = to_remove[i]
        self.loaded_tiles[k] = nil
        if self.tiles and self.tiles[k] then
            self.tiles[k] = nil
        end
        removed_any = true
    end
    if removed_any then
        self.tiles_dirty = true
    end
end

-- Rebuild merged polygon graph across all loaded tiles
function TileManager:rebuild_merged_graph()
    local merged = {}
    for _, pack in pairs(self.tiles) do
        local polys = pack.polygons
        if polys and #polys > 0 then
            for i = 1, #polys do
                merged[#merged + 1] = polys[i]
            end
        end
    end
    self.all_polygons = merged
    if #merged > 0 then
        self:build_graph(merged)
    else
        self.graph = { nodes = {}, edges = {} }
        self.poly_lookup = {}
        self.edge_index = {}
    end
end

-- Schedule an incremental (time-sliced) graph rebuild job
function TileManager:schedule_incremental_graph_build()
    if self.graph_job and coroutine.status(self.graph_job) ~= "dead" then return end
    local merged = {}
    local t_collect0 = core.cpu_ticks and core.cpu_ticks() or 0
    for _, pack in pairs(self.tiles) do
        local polys = pack.polygons
        if polys and #polys > 0 then
            for i = 1, #polys do
                merged[#merged + 1] = polys[i]
            end
        end
    end
    local t_collect1 = core.cpu_ticks and core.cpu_ticks() or 0
    local collect_ms = ticks_to_ms((t_collect1 or 0) - (t_collect0 or 0))
    self.all_polygons = merged
    self.graph = { nodes = {}, edges = {} }
    self.edge_index = {}
    self.poly_lookup = {}

    local function edge_dist2_xy(p, a, b)
        local ax, ay = a.x, a.y
        local bx, by = b.x, b.y
        local px, py = p.x, p.y
        local abx, aby = bx - ax, by - ay
        local apx, apy = px - ax, py - ay
        local ab2 = abx * abx + aby * aby
        if ab2 <= 1e-6 then
            local dx, dy = px - ax, py - ay
            return dx * dx + dy * dy
        end
        local t = (apx * abx + apy * aby) / ab2
        if t < 0 then t = 0 elseif t > 1 then t = 1 end
        local qx, qy = ax + t * abx, ay + t * aby
        local dx, dy = px - qx, py - qy
        return dx * dx + dy * dy
    end
    local function compute_clearance(coords, center)
        if not coords or #coords < 2 then return 0 end
        local min_d2 = 1e30
        for i = 1, #coords do
            local a = coords[i]
            local b = coords[(i % #coords) + 1]
            local d2 = edge_dist2_xy(center, a, b)
            if d2 < min_d2 then min_d2 = d2 end
        end
        return math.sqrt(min_d2)
    end
    -- slope metrics removed (redundant when only using walkable areas)
    local function q(v)
        -- Use 3D quantization to avoid false matches between stacked surfaces (bridge vs ground)
        -- Relax Z tolerance to better stitch across tile seams where small height mismatches exist
        local sxy = 0.35
        local sz = 0.60
        local x = math.floor(v.x / sxy + 0.5)
        local y = math.floor(v.y / sxy + 0.5)
        local z = math.floor(v.z / sz + 0.5)
        return tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)
    end
    local function edge_key(pa, pb)
        local a1, a2 = q(pa), q(pb)
        if a1 < a2 then return a1 .. "|" .. a2 else return a2 .. "|" .. a1 end
    end

    local i = 1
    self.graph_job = coroutine.create(function()
        local t_build0 = core.cpu_ticks and core.cpu_ticks() or 0
        local hz = core.cpu_ticks_per_second and core.cpu_ticks_per_second() or 0
        local inner_budget_ms = (self.graph_inner_budget_ms or self.graph_target_batch_ms or 2.5)
        local inner_budget_ticks = (hz > 0) and (inner_budget_ms * hz / 1000.0) or 0
        -- Tiny quantization cache to avoid recomputing string keys for the same vertex tables
        local quant_cache = {}
        local function q_cached(v)
            local cached = quant_cache[v]
            if cached then return cached end
            local sxy = 0.35
            local sz = 0.60
            local x = math.floor(v.x / sxy + 0.5)
            local y = math.floor(v.y / sxy + 0.5)
            local z = math.floor(v.z / sz + 0.5)
            local key = tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)
            quant_cache[v] = key
            return key
        end
        local function edge_key_cached(pa, pb)
            local a1, a2 = q_cached(pa), q_cached(pb)
            if a1 < a2 then return a1 .. "|" .. a2 else return a2 .. "|" .. a1 end
        end
        while i <= #merged do
            local batch = self.graph_batch_size or 200
            local until_i = math.min(#merged, i + batch)
            local t_batch0 = core.cpu_ticks and core.cpu_ticks() or 0
            local t_slice0 = t_batch0
            for k = i, until_i do
                local poly = merged[k]
                local area_id = poly.areaAndtype % 64
                local clearance = compute_clearance(poly.coords, poly.center)
                self.graph.nodes[k] = { id = k, center = poly.center, area = area_id, clearance = clearance }
                self.graph.edges[k] = {}
                self.poly_lookup[k] = poly
                if poly.neis and #poly.neis > 0 then
                    for j = 1, poly.vertex_count do
                        local nei = poly.neis[j]
                        -- Lua 5.1: no bitops; check high bit by range instead of '&'
                        if nei and nei > 0 and nei < 0x8000 then
                            local nb = nei
                            if nb ~= k then table.insert(self.graph.edges[k], nb) end
                        end
                    end
                end
                -- Always also build geometric adjacency to connect within tiles and across tiles/layers
                if poly.coords and #poly.coords >= 2 then
                    for j = 1, #poly.coords do
                        local a = poly.coords[j]
                        local b = poly.coords[(j % #poly.coords) + 1]
                        if a and b then
                            local key = edge_key_cached(a, b)
                            local owner = self.edge_index[key]
                            if owner and owner ~= k then
                                table.insert(self.graph.edges[k], owner)
                                table.insert(self.graph.edges[owner], k)
                            else
                                self.edge_index[key] = k
                            end
                        end
                    end
                end
                if inner_budget_ticks > 0 then
                    local now_ticks = core.cpu_ticks and core.cpu_ticks() or 0
                    if (now_ticks - t_slice0) >= inner_budget_ticks then
                        coroutine.yield()
                        t_slice0 = core.cpu_ticks and core.cpu_ticks() or now_ticks
                    end
                end
            end
            local t_batch1 = core.cpu_ticks and core.cpu_ticks() or 0
            local batch_ms = ticks_to_ms((t_batch1 or 0) - (t_batch0 or 0))
            if self.profile_enabled and batch_ms > (self.profile_threshold_ms * 1.5) then
                core.log(string.format("[Perf] graph batch %d..%d time=%.2fms (collect=%.2fms)", i, until_i, batch_ms, collect_ms))
            end
            -- Adapt batch size to target per-batch time
            local target = self.graph_target_batch_ms or 2.5
            if batch_ms > 0.1 then
                local scale = target / batch_ms
                if scale < 0.7 then
                    batch = math.max(self.graph_min_batch or 50, math.floor((until_i - i + 1) * 0.7))
                elseif scale > 1.4 then
                    batch = math.min(self.graph_max_batch or 350, math.floor((until_i - i + 1) * 1.3))
                end
                self.graph_batch_size = batch
            end
            i = until_i + 1
            coroutine.yield()
        end
        local t_build1 = core.cpu_ticks and core.cpu_ticks() or 0
        local build_ms = ticks_to_ms((t_build1 or 0) - (t_build0 or 0))
        if self.profile_enabled and build_ms > (self.profile_threshold_ms * 2) then
            core.log(string.format("[Perf] graph build total=%.2fms (#polys=%d)", build_ms, #merged))
        end
        -- Bump build id to invalidate outdated path/poly ids computed on older graphs
        self.graph_build_id = (self.graph_build_id or 0) + 1
    end)
end

function TileManager:step_graph_job_with_budget()
    if not self.graph_job or coroutine.status(self.graph_job) == "dead" then return end
    local hz = core.cpu_ticks_per_second() or 0
    local start_ticks = core.cpu_ticks() or 0
    local budget_ms = self.job_time_budget_ms or 0.5
    local budget_ticks = (hz > 0) and (budget_ms * hz / 1000.0) or 0
    repeat
        local ok, err = coroutine.resume(self.graph_job)
        if not ok then
            core.log_error("graph_job error: " .. tostring(err))
            self.graph_job = nil
            return
        end
        if coroutine.status(self.graph_job) == "dead" then
            self.graph_job = nil
            return
        end
    until ((core.cpu_ticks() or start_ticks) - start_ticks) >= budget_ticks
end

-- Optionally complete the current graph build now, within a max time budget (ms)
function TileManager:finish_graph_build_now(max_ms)
    if not self.graph_job or coroutine.status(self.graph_job) == "dead" then return end
    local hz = core.cpu_ticks_per_second() or 0
    local start_ticks = core.cpu_ticks() or 0
    local budget_ticks = (hz > 0) and ((max_ms or 30.0) * hz / 1000.0) or 0
    while self.graph_job and coroutine.status(self.graph_job) ~= "dead" do
        local ok, err = coroutine.resume(self.graph_job)
        if not ok then
            core.log_error("graph_job error: " .. tostring(err))
            self.graph_job = nil
            break
        end
        if budget_ticks > 0 then
            local now = core.cpu_ticks() or start_ticks
            if (now - start_ticks) >= budget_ticks then break end
        end
    end
end

-- Fully finish the current graph build (blocking) regardless of time; returns true if finished
function TileManager:force_build_graph_now()
    local finished = false
    while self.graph_job and coroutine.status(self.graph_job) ~= "dead" do
        local ok, err = coroutine.resume(self.graph_job)
        if not ok then
            core.log_error("graph_job error: " .. tostring(err))
            self.graph_job = nil
            break
        end
    end
    if not self.graph_job or coroutine.status(self.graph_job) == "dead" then
        finished = true
        self.graph_job = nil
    end
    return finished
end

-- Create navigation mesh data structure (FIXED VERSION)
function TileManager:create_navmesh(tile_data)
    dlog(self, "=== FIXED NAVMESH CREATION ===")
    dlog(self, "Tile data: vertCount=" .. tile_data.vertCount .. ", detailVertCount=" .. tile_data.detailVertCount .. ", polyCount=" .. tile_data.polyCount)
    
    local navmesh = {
        vertices = {},   -- array of {x, y, z} in game coordinates
        triangles = {}   -- array of {i0, i1, i2} indices into vertices
    }
    
    -- Vertices in mmaps are already in world coordinates (Recast space). We'll only axis-swap to game space.
    local tile_x, tile_y = self.current_tile.x, self.current_tile.y
    dlog(self, "Tile (" .. tile_x .. "," .. tile_y .. ") using world-space vertices from tile data")

    -- Build base vertices from dtMesh vertices
    local base_vertices = {}
    for i = 0, tile_data.vertCount - 1 do
        local x = tile_data.vertices[i * 3 + 1]
        local y = tile_data.vertices[i * 3 + 2]
        local z = tile_data.vertices[i * 3 + 3]
        local gx, gy, gz = toGameCoordinates(x, y, z)
        base_vertices[i] = { x = gx, y = gy, z = gz }
    end

    -- Build detail vertices
    local detail_vertices = {}
    for i = 1, tile_data.detailVertCount do
        local x, y, z = tile_data.getDetailVertWorld(i)
        local gx, gy, gz = toGameCoordinates(x, y, z)
        detail_vertices[i - 1] = { x = gx, y = gy, z = gz } -- zero-based
    end

    -- Use structured fields
    local polys = tile_data.polys or {}
    local detail_tris = tile_data.detailTris or {}
    local detail_meshes = tile_data.detailMeshes or {}

    local triangles_added = 0
    local triangles_skipped = 0
    local vertex_resolution_stats = { base = 0, detail = 0, failed = 0 }

    local t_tris0 = core.cpu_ticks and core.cpu_ticks() or 0
    for poly_idx, poly in ipairs(polys) do
        local dmesh = detail_meshes[poly_idx]
        if dmesh then
            -- Mask off high bits from triBase and vertBase (fix for corrupted indices)
            local triBase_masked = dmesh.triBase % 1048576  -- Remove high bits (2^20)
            local vertBase_masked = dmesh.vertBase % 1048576
            
            -- Skip meshes with invalid triBase values
            if triBase_masked >= #detail_tris then
                triangles_skipped = triangles_skipped + dmesh.triCount
            else
                for t = 0, dmesh.triCount - 1 do
                    local tri_idx = triBase_masked + t + 1 -- 1-based
                    if tri_idx <= #detail_tris then
                        local tri = detail_tris[tri_idx]
                        local tri_vertices = {}

                        for _, idx in ipairs{ tri.vertIndex0, tri.vertIndex1, tri.vertIndex2 } do
                            local vertex
                            if idx < poly.vertCount then
                                -- Reference into dtMesh vertices via dtPoly.verts
                                local base_vert_idx = poly.verts[idx + 1] -- Convert to 1-based
                                if base_vert_idx and base_vertices[base_vert_idx] then
                                    vertex = base_vertices[base_vert_idx]
                                    vertex_resolution_stats.base = vertex_resolution_stats.base + 1
                                end
                            else
                                -- Reference into detailVerts starting at vertBase
                                local detail_vert_idx = vertBase_masked + (idx - poly.vertCount)
                                if detail_vertices[detail_vert_idx] then
                                    vertex = detail_vertices[detail_vert_idx]
                                    vertex_resolution_stats.detail = vertex_resolution_stats.detail + 1
                                end
                            end
                            
                            if vertex then
                                local idx = #navmesh.vertices + 1
                                navmesh.vertices[idx] = vertex
                                table.insert(tri_vertices, idx)
                            else
                                vertex_resolution_stats.failed = vertex_resolution_stats.failed + 1
                            end
                        end

                        -- Only add triangle if we have all 3 vertices
                        if #tri_vertices == 3 then
                            -- Check for degenerate triangles (same vertex used multiple times)
                            if tri_vertices[1] == tri_vertices[2] or tri_vertices[2] == tri_vertices[3] or tri_vertices[1] == tri_vertices[3] then
                                triangles_skipped = triangles_skipped + 1
                            else
                                -- Check triangle edge lengths - skip triangles with edges too long
                                local v1 = navmesh.vertices[tri_vertices[1]]
                                local v2 = navmesh.vertices[tri_vertices[2]]
                                local v3 = navmesh.vertices[tri_vertices[3]]
                                
                                local d1 = math.sqrt((v2.x-v1.x)^2 + (v2.y-v1.y)^2 + (v2.z-v1.z)^2)
                                local d2 = math.sqrt((v3.x-v2.x)^2 + (v3.y-v2.y)^2 + (v3.z-v2.z)^2)
                                local d3 = math.sqrt((v1.x-v3.x)^2 + (v1.y-v3.y)^2 + (v1.z-v3.z)^2)
                                
                                local max_edge = math.max(d1, d2, d3)
                                
                                -- Skip triangles with edges longer than reasonable navmesh polygon size
                                if max_edge > 50.0 then -- 50 units max edge length
                                    triangles_skipped = triangles_skipped + 1
                                else
                                    table.insert(navmesh.triangles, tri_vertices)
                                    triangles_added = triangles_added + 1
                                end
                            end
                        else
                            triangles_skipped = triangles_skipped + 1
                        end
                    end
                end
            end
        end
    end
    
    local t_tris1 = core.cpu_ticks and core.cpu_ticks() or 0
    local tri_ms = ticks_to_ms((t_tris1 or 0) - (t_tris0 or 0))
    if self.profile_enabled and tri_ms > self.profile_threshold_ms then
        core.log(string.format("[Perf] navmesh triangles time=%.2fms (polys=%d, tris_added=%d, tris_skipped=%d)", tri_ms, #polys, triangles_added, triangles_skipped))
    end
    dlog(self, "=== FIXED NAVMESH CREATION COMPLETE ===")
    dlog(self, "Final navmesh: " .. #navmesh.vertices .. " unique vertices, " .. #navmesh.triangles .. " triangles")
    dlog(self, "Triangles: " .. triangles_added .. " added, " .. triangles_skipped .. " skipped")
    dlog(self, "Vertex resolution: " .. vertex_resolution_stats.base .. " base, " .. vertex_resolution_stats.detail .. " detail, " .. vertex_resolution_stats.failed .. " failed")
    
    return navmesh
end

-- Geometry helpers
local function point_in_polygon_xy(point, coords)
    if not coords or #coords < 3 then return false end
    local x, y = point.x, point.y
    local inside = false
    local j = #coords
    for i = 1, #coords do
        local xi, yi = coords[i].x, coords[i].y
        local xj, yj = coords[j].x, coords[j].y
        local intersect = ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / ((yj - yi) ~= 0 and (yj - yi) or 1e-9) + xi)
        if intersect then inside = not inside end
        j = i
    end
    return inside
end

local function is_walkable_xy(self, p)
    local polys = self.all_polygons or {}
    for i = 1, #polys do
        local poly = polys[i]
        if poly and poly.coords and point_in_polygon_xy(p, poly.coords) then
            return true, poly
        end
    end
    return false, nil
end

-- Build a simple graph from polygons: nodes at polygon centers, edges for shared edges
function TileManager:build_graph(polygons)
    self.graph = { nodes = {}, edges = {} }
    self.edge_index = {}
    self.poly_lookup = {}

    local function edge_dist2_xy(p, a, b)
        local ax, ay = a.x, a.y
        local bx, by = b.x, b.y
        local px, py = p.x, p.y
        local abx, aby = bx - ax, by - ay
        local apx, apy = px - ax, py - ay
        local ab2 = abx * abx + aby * aby
        if ab2 <= 1e-6 then
            local dx, dy = px - ax, py - ay
            return dx * dx + dy * dy
        end
        local t = (apx * abx + apy * aby) / ab2
        if t < 0 then t = 0 elseif t > 1 then t = 1 end
        local qx, qy = ax + t * abx, ay + t * aby
        local dx, dy = px - qx, py - qy
        return dx * dx + dy * dy
    end

    local function compute_clearance(coords, center)
        if not coords or #coords < 2 then return 0 end
        local min_d2 = 1e30
        for i = 1, #coords do
            local a = coords[i]
            local b = coords[(i % #coords) + 1]
            local d2 = edge_dist2_xy(center, a, b)
            if d2 < min_d2 then min_d2 = d2 end
        end
        return math.sqrt(min_d2)
    end

    local function compute_slope_tan(coords)
        if not coords or #coords < 3 then return 0 end
        local p1 = coords[1]
        local nx, ny, nz = 0, 0, 0
        for i = 2, #coords - 1 do
            local p2 = coords[i]
            local p3 = coords[i + 1]
            local ux, uy, uz = p2.x - p1.x, p2.y - p1.y, p2.z - p1.z
            local vx, vy, vz = p3.x - p1.x, p3.y - p1.y, p3.z - p1.z
            nx = nx + (uy * vz - uz * vy)
            ny = ny + (uz * vx - ux * vz)
            nz = nz + (ux * vy - uy * vx)
        end
        local horiz = math.sqrt(nx * nx + ny * ny)
        if nz == 0 then return 1e6 end
        return math.abs(horiz / nz)
    end

    local function q(v)
    local s = 0.35 -- 35cm bins to better merge across tiles while limiting duplicates
        local x = math.floor(v.x / s + 0.5)
        local y = math.floor(v.y / s + 0.5)
        return tostring(x) .. "," .. tostring(y)
    end

    local function edge_key(pa, pb)
        local a1, a2 = q(pa), q(pb)
        if a1 < a2 then return a1 .. "|" .. a2 else return a2 .. "|" .. a1 end
    end

    -- Create nodes; index edges by world position to connect across tiles
    for i, poly in ipairs(polygons) do
        local area_id = poly.areaAndtype % 64
        local clearance = compute_clearance(poly.coords, poly.center)
        self.graph.nodes[i] = { id = i, center = poly.center, area = area_id, clearance = clearance }
        self.graph.edges[i] = {}
        self.poly_lookup[i] = poly
        -- Prefer Detour neighbor refs where available (intra-tile)
        if poly.neis and #poly.neis > 0 then
            for j = 1, poly.vertex_count do
                local nei = poly.neis[j]
                if nei and nei > 0 and nei < 0x8000 then
                    local nb = nei
                    if nb >= 1 and nb <= #polygons and nb ~= i then
                        table.insert(self.graph.edges[i], nb)
                    end
                end
            end
        end
        -- Geometric adjacency to connect across tiles/layers (until link.ref decoding is implemented)
        if poly.coords and #poly.coords >= 2 then
            for j = 1, #poly.coords do
                local a = poly.coords[j]
                local b = poly.coords[(j % #poly.coords) + 1]
                if a and b then
                    local key = edge_key(a, b)
                    local owner = self.edge_index[key]
                    if owner and owner ~= i then
                        table.insert(self.graph.edges[i], owner)
                        table.insert(self.graph.edges[owner], i)
                    else
                        self.edge_index[key] = i
                    end
                end
            end
        end
    end
end

-- A* over polygon centers
local function heuristic(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function TileManager:find_closest_node(pos)
    if not self.graph or not self.graph.nodes then return nil end
    local best, best_id = 1e30, nil
    for id, n in pairs(self.graph.nodes) do
        local c = n.center
        local d = (c.x - pos.x) ^ 2 + (c.y - pos.y) ^ 2 + (c.z - pos.z) ^ 2
        if d < best then best = d; best_id = id end
    end
    return best_id
end

function TileManager:reconstruct_poly_path(came_from, current)
    local ids = {}
    while current do
        table.insert(ids, 1, current)
        current = came_from[current]
    end
    return ids
end

-- Utility: total 3D length of a point path
local function path_total_length(points)
    if not points or #points < 2 then return 0 end
    local sum = 0
    for i = 2, #points do
        local a = points[i - 1]
        local b = points[i]
        local dx = (b.x or 0) - (a.x or 0)
        local dy = (b.y or 0) - (a.y or 0)
        local dz = (b.z or 0) - (a.z or 0)
        sum = sum + math.sqrt(dx * dx + dy * dy + dz * dz)
    end
    return sum
end

-- Forward declaration for linter: defined later in the file
local path_inside_corridor
local clamp_point_to_polygon
local choose_owner_poly_for_point
local sample_z_from_detail

-- Geometry helpers for path correction
local function nearest_point_on_segment(a, b, p)
    local ax, ay, az = a.x or 0, a.y or 0, a.z or 0
    local bx, by, bz = b.x or 0, b.y or 0, b.z or 0
    local px, py, pz = p.x or 0, p.y or 0, p.z or 0
    local abx, aby, abz = bx - ax, by - ay, bz - az
    local apx, apy, apz = px - ax, py - ay, pz - az
    local ab2 = abx * abx + aby * aby + abz * abz
    if ab2 <= 1e-9 then return { x = ax, y = ay, z = az }, 0 end
    local t = (apx * abx + apy * aby + apz * abz) / ab2
    if t < 0 then t = 0 elseif t > 1 then t = 1 end
    return { x = ax + abx * t, y = ay + aby * t, z = az + abz * t }, t
end

local function nearest_point_on_polyline(polyline, p)
    if not polyline or #polyline < 2 then return nil end
    local best_pt, best_d2 = nil, 1e30
    for i = 2, #polyline do
        local q, _ = nearest_point_on_segment(polyline[i - 1], polyline[i], p)
        local dx = (q.x or 0) - (p.x or 0)
        local dy = (q.y or 0) - (p.y or 0)
        local dz = (q.z or 0) - (p.z or 0)
        local d2 = dx * dx + dy * dy + dz * dz
        if d2 < best_d2 then best_d2 = d2; best_pt = q end
    end
    return best_pt
end

-- Move points outside the corridor back towards the original safe path
local function constrain_path_to_corridor(points, safe_points, poly_ids, poly_lookup)
    if not points or #points == 0 then return points end
    local result = {}
    for i = 1, #points do
        local p = points[i]
        if path_inside_corridor({ p }, poly_ids, poly_lookup) then
            result[i] = p
        else
            local anchor = nearest_point_on_polyline(safe_points, p) or p
            -- Binary search along p->anchor to find a point inside the corridor
            local lo, hi = 0.0, 1.0
            local found = p
            for _ = 1, 10 do
                local t = 0.5 * (lo + hi)
                local q = {
                    x = p.x + (anchor.x - p.x) * t,
                    y = p.y + (anchor.y - p.y) * t,
                    z = p.z + (anchor.z - p.z) * t,
                }
                if path_inside_corridor({ q }, poly_ids, poly_lookup) then
                    found = q
                    hi = t
                else
                    lo = t
                end
            end
            result[i] = found
        end
    end
    return result
end

-- Round sharp corners within corridor with constant-radius arcs (keeps inside polys)
local function round_corners_in_corridor(points, poly_ids, poly_lookup, turn_radius, steps)
    if not points or #points < 3 then return points end
    local r = math.max(0.1, turn_radius or 2.5)
    local k = math.max(2, math.floor(steps or 4))
    local out = { points[1] }
    for i = 2, #points - 1 do
        local p0, p1, p2 = points[i - 1], points[i], points[i + 1]
        local v1x, v1y = p1.x - p0.x, p1.y - p0.y
        local v2x, v2y = p2.x - p1.x, p2.y - p1.y
        local len1 = math.sqrt(v1x * v1x + v1y * v1y)
        local len2 = math.sqrt(v2x * v2x + v2y * v2y)
        if len1 < 1e-3 or len2 < 1e-3 then
            out[#out + 1] = p1
        else
            v1x, v1y = v1x / len1, v1y / len1
            v2x, v2y = v2x / len2, v2y / len2
            local dot = v1x * v2x + v1y * v2y
            dot = math.max(-1, math.min(1, dot))
            local ang = math.acos(dot)
            if ang < math.rad(135) then
                local t1 = math.min(len1 * 0.5, r)
                local t2 = math.min(len2 * 0.5, r)
                local a = { x = p1.x - v1x * t1, y = p1.y - v1y * t1, z = p1.z }
                local b = { x = p1.x + v2x * t2, y = p1.y + v2y * t2, z = p1.z }
                -- Sweep arc from a to b around p1
                for s = 1, k do
                    local t = s / (k + 1)
                    local tx = a.x * (1 - t) + b.x * t
                    local ty = a.y * (1 - t) + b.y * t
                    local cand = { x = tx, y = ty, z = p1.z }
                    -- Clamp candidate into corridor and project Z
                    local owner = choose_owner_poly_for_point and choose_owner_poly_for_point(cand, poly_ids, poly_lookup) or nil
                    if owner then
                        cand = clamp_point_to_polygon(cand, owner)
                    end
                    out[#out + 1] = cand
                end
            else
                out[#out + 1] = p1
            end
        end
    end
    out[#out + 1] = points[#points]
    return out
end

function TileManager:a_star(start_id, goal_id)
    if not start_id or not goal_id then return nil end
    local open = { [start_id] = true }
    local open_list = { start_id }
    local came_from = {}
    local g = { [start_id] = 0 }
    local h = {}
    h[start_id] = heuristic(self.graph.nodes[start_id].center, self.graph.nodes[goal_id].center)

    while #open_list > 0 do
        -- pop lowest f = g + h
        local best_idx, best_id, best_f = 1, open_list[1], (g[open_list[1]] or 1e30) + (h[open_list[1]] or 0)
        for i = 2, #open_list do
            local id = open_list[i]
            local f = (g[id] or 1e30) + (h[id] or 0)
            if f < best_f then best_f = f; best_idx = i; best_id = id end
        end
        table.remove(open_list, best_idx)
        open[best_id] = nil

        if best_id == goal_id then
            return self:reconstruct_poly_path(came_from, best_id)
        end

        for _, nb in ipairs(self.graph.edges[best_id] or {}) do
            local n_best = self.graph.nodes[best_id]
            local n_nb = self.graph.nodes[nb]
            -- Base movement cost
            local cost = heuristic(n_best.center, n_nb.center)
            -- Clearance bias (prefer wide polys)
            local min_clear = self.min_clearance or 1.5
            local w_clear = self.weight_clearance or 0.25
            local clearance = math.min(n_best.clearance or 0, n_nb.clearance or 0)
            if clearance < min_clear then
                local penalty = (min_clear - clearance) * 2.0
                cost = cost + penalty * w_clear
            else
                local bonus = math.min(3.0, (clearance - min_clear))
                cost = cost - bonus * w_clear * 0.5
            end
            -- Vertical layer cohesion: penalize large z jumps to discourage bridge<->ground hops
            local w_layer = self.weight_layer or 2.0
            local dz = math.abs((n_best.center.z or 0) - (n_nb.center.z or 0))
            if dz > 0.8 then
                cost = cost + w_layer * math.min(5.0, dz)
            end
            -- Bias against water (area 9) to avoid swimming when possible
            if (n_best.area == 9) or (n_nb.area == 9) then
                cost = cost + 5.0
            end

            local tentative_g = (g[best_id] or 1e30) + cost
            if tentative_g < (g[nb] or 1e30) then
                came_from[nb] = best_id
                g[nb] = tentative_g
                h[nb] = h[nb] or heuristic(self.graph.nodes[nb].center, self.graph.nodes[goal_id].center)
                if not open[nb] then
                    open[nb] = true
                    table.insert(open_list, nb)
                end
            end
        end
    end
    return nil
end

-- Compute up to k alternative simple paths by discouraging previously used edges
function TileManager:compute_k_paths(start_id, goal_id, k)
    local results = {}
    local discouraged = {} -- soft penalties
    local bans = {}        -- hard-banned edges per iteration: set of key->true
    local seen = {}
    local function edge_key(a, b)
        if (not a) or (not b) then return nil end
        if a < b then return tostring(a).."-"..tostring(b) else return tostring(b).."-"..tostring(a) end
    end
    local function local_a_star()
        if not start_id or not goal_id then return nil end
        local open = { [start_id] = true }
        local open_list = { start_id }
        local came_from = {}
        local g = { [start_id] = 0 }
        local h = {}
        h[start_id] = heuristic(self.graph.nodes[start_id].center, self.graph.nodes[goal_id].center)
        while #open_list > 0 do
            local best_idx, best_id, best_f = 1, open_list[1], (g[open_list[1]] or 1e30) + (h[open_list[1]] or 0)
            for i = 2, #open_list do
                local id = open_list[i]
                local f = (g[id] or 1e30) + (h[id] or 0)
                if f < best_f then best_f = f; best_idx = i; best_id = id end
            end
            table.remove(open_list, best_idx)
            open[best_id] = nil
            if best_id == goal_id then
                return self:reconstruct_poly_path(came_from, best_id)
            end
            for _, nb in ipairs(self.graph.edges[best_id] or {}) do
                local n_best = self.graph.nodes[best_id]
                local n_nb = self.graph.nodes[nb]
                local cost = heuristic(n_best.center, n_nb.center)
                local min_clear = self.min_clearance or 1.5
                local w_clear = self.weight_clearance or 0.25
                local clearance = math.min(n_best.clearance or 0, n_nb.clearance or 0)
                if clearance < min_clear then
                    local penalty = (min_clear - clearance) * 2.0
                    cost = cost + penalty * w_clear
                else
                    local bonus = math.min(3.0, (clearance - min_clear))
                    cost = cost - bonus * w_clear * 0.5
                end
                local w_layer = self.weight_layer or 2.0
                local dz = math.abs((n_best.center.z or 0) - (n_nb.center.z or 0))
                if dz > 0.8 then cost = cost + w_layer * math.min(5.0, dz) end
                if (n_best.area == 9) or (n_nb.area == 9) then cost = cost + 5.0 end
                -- Discourage previously used edges to diversify results
                local ek = edge_key(best_id, nb)
                if ek then
                    if bans[ek] then
                        cost = cost + 1e6 -- effectively ban this edge for this run
                    end
                    local times = discouraged[ek] or 0
                    if times > 0 then cost = cost + times * 50.0 end
                end
                local tentative_g = (g[best_id] or 1e30) + cost
                if tentative_g < (g[nb] or 1e30) then
                    came_from[nb] = best_id
                    g[nb] = tentative_g
                    h[nb] = h[nb] or heuristic(self.graph.nodes[nb].center, self.graph.nodes[goal_id].center)
                    if not open[nb] then open[nb] = true; table.insert(open_list, nb) end
                end
            end
        end
        return nil
    end
    local max_k = math.max(1, math.floor(k or 1))
    for iter = 1, max_k do
        local poly_ids = local_a_star()
        if not poly_ids or #poly_ids == 0 then break end
        local key = table.concat(poly_ids, ",")
        if seen[key] then
            -- Already have this path; discourage mid-edge more strongly and retry
            if #poly_ids >= 2 then
                local mid = math.floor(#poly_ids / 2)
                local ekm = edge_key(poly_ids[mid], poly_ids[mid + 1])
                if ekm then discouraged[ekm] = (discouraged[ekm] or 0) + 3 end
            end
        else
            table.insert(results, poly_ids)
            seen[key] = true
            -- Prepare next iteration with a different logic:
            -- Choose a spur point along the last path and hard-ban that outgoing edge to force a different branch.
            if #poly_ids >= 2 then
                local pivot
                if (iter % 3) == 1 then
                    pivot = 2 -- near start
                elseif (iter % 3) == 2 then
                    pivot = math.floor(#poly_ids / 2) -- middle
                else
                    pivot = #poly_ids - 1 -- near end
                end
                local eka = edge_key(poly_ids[pivot], poly_ids[pivot + 1])
                if eka then bans[eka] = true end
            end
        end
        -- Discourage edges from this solution for the next run
        for i = 1, #poly_ids - 1 do
            local a, b = poly_ids[i], poly_ids[i + 1]
            local ek = edge_key(a, b)
            if ek then
                discouraged[ek] = (discouraged[ek] or 0) + 1
            end
        end
    end
    return results
end

function TileManager:compute_path_to_saved()
    if not self.saved_position then
        core.log_warning("No saved position set")
        return
    end
    local player = core.object_manager.get_local_player()
    if not player then return end
    local start_pos = player:get_position()
    -- Make sure we have tiles around start and goal; rebuild only if anything changed
    local sx, sy = mesh_helper.get_tile_coordinates(start_pos.x, start_pos.y)
    local gx, gy = mesh_helper.get_tile_coordinates(self.saved_position.x, self.saved_position.y)
    -- Ensure start/goal neighborhoods are loaded with a slightly higher budget for responsiveness
    -- Load a symmetric window [-r, +r] around start and goal (default r=2)
    local r = self.tile_load_radius or 2
    local c1 = self:ensure_neighbor_tiles_loaded(sx, sy, r, 12.0)
    local c2 = self:ensure_neighbor_tiles_loaded(gx, gy, r, 12.0)
    if c1 or c2 then
        self:schedule_incremental_graph_build()
        -- Force complete build so a path is guaranteed
        self:force_build_graph_now()
    end
    if not self.graph or not self.graph.nodes or next(self.graph.nodes) == nil then
        -- Try to kick a build if not scheduled yet
        self:schedule_incremental_graph_build()
        -- As a fallback, fully finish the build now
        self:force_build_graph_now()
        if not self.graph or not self.graph.nodes or next(self.graph.nodes) == nil then
            core.log_warning("Graph not ready")
            return
        end
    end
    local start_id = self:find_closest_node(start_pos)
    local goal_id = self:find_closest_node(self.saved_position)
    if not start_id or not goal_id then
        core.log_warning("Failed to find start/goal nodes")
        return
    end
    local alt_sets = self:compute_k_paths(start_id, goal_id, 10)
    if not alt_sets or #alt_sets == 0 then
        core.log_warning("A* returned no path")
        return
    end
    -- Convert and score paths; keep top 10 by length
    local best_nodes, best_polys
    local alt_nodes = {}
    for idx = 1, math.min(10, #alt_sets) do
        local ids = alt_sets[idx]
        -- Prefer funnel path; fallback to center corridor if extraction fails
        local safe_corridor = self:build_portal_center_path(ids)
        local funnel = self:build_funnel_path(ids, start_pos, self.saved_position)
        local corridor = funnel and path_inside_corridor(funnel, ids, self.poly_lookup) and funnel or safe_corridor
        if (not self.strict_detour_mode) and self.smooth_path_enabled then
            local raw_before = corridor
            corridor = self:simplify_path(corridor, self.simplify_tolerance or 3.0)
            corridor = self:chaikin_smooth(corridor, self.smooth_iterations or 3)
            corridor = visibility_straighten(corridor, ids, self.poly_lookup, 2.0)
            if (not corridor) or (#corridor < 3) then
                corridor = raw_before
            elseif not path_inside_corridor(corridor, ids, self.poly_lookup) then
                corridor = constrain_path_to_corridor(corridor, safe_corridor, ids, self.poly_lookup)
            end
        end
        -- Project path nodes onto polygon planes to ensure they lie on the flat corridor surface
        local projected = {}
        for i = 1, #corridor do
            local p = corridor[i]
            -- Prefer containing polygon with closest plane-z; fallback to nearest edge among ids
            local owner = choose_owner_poly_for_point and choose_owner_poly_for_point(p, ids, self.poly_lookup) or nil
            if not owner then
                local best_d2
                for _, pid in ipairs(ids) do
                    local poly = self.poly_lookup[pid]
                    if poly and poly.coords and #poly.coords >= 2 then
                        for j = 1, #poly.coords do
                            local a = poly.coords[j]
                            local b = poly.coords[(j % #poly.coords) + 1]
                            local q, _ = nearest_point_on_segment(a, b, p)
                            local dx, dy = (q.x - p.x), (q.y - p.y)
                            local d2 = dx * dx + dy * dy
                            if not best_d2 or d2 < best_d2 then best_d2 = d2; owner = poly end
                        end
                    end
                end
            end
            local snapped = owner and clamp_point_to_polygon(p, owner) or p
            projected[i] = snapped
        end
        corridor = projected
        if self.round_corners_enabled and self.strict_detour_mode then
            corridor = round_corners_in_corridor(corridor, ids, self.poly_lookup, self.min_turn_radius, self.round_steps)
        end
        -- Keep for potential inspection, but we won't draw these anymore
        alt_nodes[#alt_nodes + 1] = corridor
        -- Score by actual path distance (prefer shortest physical distance)
        local dist = path_total_length(corridor)
        if not best_nodes or dist < (path_total_length(best_nodes) or 1e30) then
            best_nodes, best_polys = corridor, ids
        end
    end
    self.alt_paths_nodes = alt_nodes
    self.path_nodes = best_nodes
    self.path_poly_ids = best_polys
    self.path_graph_id = self.graph_build_id
    dlog(self, "Path with " .. #self.path_nodes .. " nodes ready")
    -- Ensure path is visible without starting movement
    self.show_path = true
end

-- Build path between two positions without modifying movement state
function TileManager:path_from_to(start_pos, end_pos)
    if not start_pos or not end_pos then return nil end
    -- Ensure tiles around start and end are loaded
    local sx, sy = mesh_helper.get_tile_coordinates(start_pos.x, start_pos.y)
    local gx, gy = mesh_helper.get_tile_coordinates(end_pos.x, end_pos.y)
    local r = self.tile_load_radius or 2
    local c1 = self:ensure_neighbor_tiles_loaded(sx, sy, r, 12.0)
    local c2 = self:ensure_neighbor_tiles_loaded(gx, gy, r, 12.0)
    if c1 or c2 then
        self:schedule_incremental_graph_build()
        self:force_build_graph_now()
    end
    if not self.graph or not self.graph.nodes or next(self.graph.nodes) == nil then
        self:schedule_incremental_graph_build()
        self:force_build_graph_now()
        if not self.graph or not self.graph.nodes or next(self.graph.nodes) == nil then return nil end
    end
    local start_id = self:find_closest_node(start_pos)
    local goal_id = self:find_closest_node(end_pos)
    if not start_id or not goal_id then return nil end
    local poly_ids = self:a_star(start_id, goal_id)
    if not poly_ids or #poly_ids == 0 then return nil end
    local safe_corridor = self:build_portal_center_path(poly_ids)
    local funnel = self:build_funnel_path(poly_ids, start_pos, end_pos)
    local corridor = funnel and path_inside_corridor(funnel, poly_ids, self.poly_lookup) and funnel or safe_corridor
    if (not self.strict_detour_mode) and self.smooth_path_enabled then
        local raw_before = corridor
        corridor = self:simplify_path(corridor, self.simplify_tolerance or 3.0)
        corridor = self:chaikin_smooth(corridor, self.smooth_iterations or 3)
        corridor = visibility_straighten(corridor, poly_ids, self.poly_lookup, 2.0)
        if (not corridor) or (#corridor < 3) then
            corridor = raw_before
        elseif not path_inside_corridor(corridor, poly_ids, self.poly_lookup) then
            corridor = constrain_path_to_corridor(corridor, safe_corridor, poly_ids, self.poly_lookup)
        end
    end
    -- Project nodes onto polygon planes for final path
    do
        local projected = {}
        for i = 1, #corridor do
            local p = corridor[i]
            local owner = choose_owner_poly_for_point and choose_owner_poly_for_point(p, poly_ids, self.poly_lookup) or nil
            if not owner then
                local best_d2
                for _, pid in ipairs(poly_ids) do
                    local poly = self.poly_lookup[pid]
                    if poly and poly.coords and #poly.coords >= 2 then
                        for j = 1, #poly.coords do
                            local a = poly.coords[j]
                            local b = poly.coords[(j % #poly.coords) + 1]
                            local q, _ = nearest_point_on_segment(a, b, p)
                            local dx, dy = (q.x - p.x), (q.y - p.y)
                            local d2 = dx * dx + dy * dy
                            if not best_d2 or d2 < best_d2 then best_d2 = d2; owner = poly end
                        end
                    end
                end
            end
            local snapped = owner and clamp_point_to_polygon(p, owner) or p
            projected[i] = snapped
        end
        corridor = projected
    end
    if self.round_corners_enabled and self.strict_detour_mode then
        corridor = round_corners_in_corridor(corridor, poly_ids, self.poly_lookup, self.min_turn_radius, self.round_steps)
    end
    -- In strict Detour mode, do not apply extra re-sampling preference
    local best = corridor
    if not self.strict_detour_mode then
        -- Re-run a local refinement: pick shorter among raw corridor and a lightly re-sampled path
        -- (safeguard against right-angle artifacts when crossing tiles)
        local alt = self:simplify_path(corridor, math.min(2.0, (self.simplify_tolerance or 3.0) * 0.66))
        if alt and #alt >= 2 and path_total_length(alt) < path_total_length(best) then
            best = alt
        end
    end
    self.path_graph_id = self.graph_build_id
    return best
end

-- Start movement along current path towards saved position
function TileManager:start_move_to_saved()
    if not self.path_nodes or #self.path_nodes < 2 then
        self:compute_path_to_saved()
    end
    if not self.path_nodes or #self.path_nodes < 2 then
        core.log_warning("No path available to move")
        return
    end
    self.move_active = true
    self.move_index = 2
    self.forward_active = false
    self.last_forward_toggle_ms = 0
    if core.input and core.input.enable_movement then core.input.enable_movement() end
    if core.input and core.input.stop_attack then core.input.stop_attack() end
    dlog(self, string.format("Move start: nodes=%d, reach=%.2f", self.path_nodes and #self.path_nodes or 0, self.move_reach_radius or 1.4))
    -- Ensure steering keys are released at start
    if self.turn_left_active then core.input.turn_left_stop(); self.turn_left_active = false end
    if self.turn_right_active then core.input.turn_right_stop(); self.turn_right_active = false end
end

-- Stop current movement and release all steering inputs
function TileManager:stop_movement()
    if self.forward_active then core.input.move_forward_stop(); self.forward_active = false end
    if self.turn_left_active then core.input.turn_left_stop(); self.turn_left_active = false end
    if self.turn_right_active then core.input.turn_right_stop(); self.turn_right_active = false end
    -- Defensive: ensure all movement keys are released
    core.input.move_backward_stop()
    core.input.strafe_left_stop()
    core.input.strafe_right_stop()
    local was_active = self.move_active
    self.move_active = false
    dlog(self, "Movement stopped. was_active=" .. tostring(was_active) .. ", move_index=" .. tostring(self.move_index) .. "/" .. tostring(self.path_nodes and #self.path_nodes or 0))
    if was_active and self.move_finish_cb then
        local cb = self.move_finish_cb
        self.move_finish_cb = nil
        cb(false)
    end
end

-- Release all movement-related inputs and clear local flags
function TileManager:release_all_inputs()
    core.input.move_forward_stop(); self.forward_active = false
    core.input.move_backward_stop()
    core.input.strafe_left_stop()
    core.input.strafe_right_stop()
    core.input.turn_left_stop(); self.turn_left_active = false
    core.input.turn_right_stop(); self.turn_right_active = false
    dlog(self, "Released all movement inputs")
end

local function vec_len2_xy(dx, dy)
    return dx * dx + dy * dy
end

-- Obstacle-aware movement that uses the path as guidance
function TileManager:update_movement()
    if not self.move_active then return end
    local player = core.object_manager.get_local_player()
    if not player or not player:is_valid() then self:stop_movement() return end
    if not self.path_nodes or #self.path_nodes < 2 then self:stop_movement() return end

    local pos = player:get_position()
    local tgt = self.path_nodes[self.move_index]
    if not tgt then self:stop_movement() return end

    -- If our heading error is very large, advance target selection to avoid oscillation around close nodes
    if self.path_nodes and self.move_index < #self.path_nodes then
        local ndx_tmp, ndy_tmp = (tgt.x - pos.x), (tgt.y - pos.y)
        local dlen_tmp = math.sqrt(ndx_tmp * ndx_tmp + ndy_tmp * ndy_tmp)
        if dlen_tmp > 1e-6 then ndx_tmp, ndy_tmp = ndx_tmp / dlen_tmp, ndy_tmp / dlen_tmp end
        local rot_tmp = player.get_rotation and player:get_rotation() or 0
        local head_tmp = math.atan(ndy_tmp, ndx_tmp)
        local err_tmp = head_tmp - rot_tmp
        while err_tmp > math.pi do err_tmp = err_tmp - 2 * math.pi end
        while err_tmp < -math.pi do err_tmp = err_tmp + 2 * math.pi end
        if math.abs(err_tmp) > (self.skip_turning_error_threshold or 2.6) then -- ~149 degrees
            local nxt = self.path_nodes[self.move_index + 1]
            if nxt then
                local d_curr2 = vec_len2_xy(tgt.x - pos.x, tgt.y - pos.y)
                local d_next2 = vec_len2_xy(nxt.x - pos.x, nxt.y - pos.y)
                if d_next2 + 0.25 < d_curr2 then
                    self.move_index = self.move_index + 1
                    tgt = nxt
                    dx = tgt.x - pos.x; dy = tgt.y - pos.y
                    dist2 = vec_len2_xy(dx, dy)
                    dlog(self, "Large heading error: skipping to next node")
                end
            end
        end
    end

    -- Hybrid assistance: detect wiggle/misalignment and trigger short look_at pulses with a per-second budget
    local now_ms = core.time() or 0
    do
        local cur_turn_state = (self.turn_left_active and 1) or (self.turn_right_active and -1) or 0
        if cur_turn_state ~= 0 and cur_turn_state ~= (self.last_turn_state or 0) then
            if (now_ms - (self.last_wiggle_reset_ms or 0)) > (self.wiggle_switch_window_ms or 800) then
                self.wiggle_switch_count = 0
                self.last_wiggle_reset_ms = now_ms
            end
            self.wiggle_switch_count = (self.wiggle_switch_count or 0) + 1
        end
        self.last_turn_state = cur_turn_state

        -- Reset/decay look_at budget every second
        if (now_ms - (self.look_at_budget_window_start_ms or 0)) >= 1000 then
            self.look_at_budget_window_start_ms = now_ms
            self.look_at_budget_used_ms = 0
        end

        -- Use current computed heading error and dot from below; if not yet set, fall back to conservative values
        local severe_misaligned = false
        do
            local heading_err = 0.0
            local facing_dot = 1.0
            do
                local ddx2, ddy2 = (tgt.x - pos.x), (tgt.y - pos.y)
                local dlen2 = math.sqrt(ddx2 * ddx2 + ddy2 * ddy2)
                local ndx2, ndy2 = ddx2, ddy2
                if dlen2 > 1e-6 then ndx2, ndy2 = ddx2 / dlen2, ddy2 / dlen2 end
                local pdir2 = player.get_direction and player:get_direction() or nil
                if pdir2 then
                    local pnx2, pny2 = pdir2.x, pdir2.y
                    local plen2 = math.sqrt(pnx2 * pnx2 + pny2 * pny2)
                    if plen2 > 1e-6 then pnx2, pny2 = pnx2 / plen2, pny2 / plen2 end
                    local dot2 = pnx2 * ndx2 + pny2 * ndy2
                    local cross2 = pnx2 * ndy2 - pny2 * ndx2
                    heading_err = math.atan(cross2, dot2)
                    facing_dot = dot2
                end
            end
            severe_misaligned = (math.abs(heading_err) > 1.2) or (facing_dot < 0.6)
        end
        local frequent_wiggle = (self.wiggle_switch_count or 0) >= 6
        local can_pulse = (self.look_at_budget_used_ms or 0) < (self.look_at_budget_ms_per_sec or 300)
        if self.assist_look_at_enabled and core.input and core.input.look_at and can_pulse and (severe_misaligned or frequent_wiggle) then
            local until_ms = now_ms + (self.look_at_pulse_ms or 150)
            if until_ms > (self.look_at_pulse_until_ms or 0) then
                self.look_at_pulse_until_ms = until_ms
                self.look_at_budget_used_ms = (self.look_at_budget_used_ms or 0) + (self.look_at_pulse_ms or 150)
                dlog(self, "Assist look_at pulse")
            end
        end
    end

    local dx = tgt.x - pos.x
    local dy = tgt.y - pos.y
    local dist2 = vec_len2_xy(dx, dy)
    local reach_radius = self.move_reach_radius or 1.4
    local is_mounted = player.is_mounted and player:is_mounted()
    if is_mounted then
        reach_radius = self.mounted_reach_radius or 2.2
    end
    local reach2 = (reach_radius) ^ 2

    -- Advance to next node if close enough
    if dist2 <= reach2 then
        dlog(self, string.format("Node %d reached (d=%.2f<=%.2f), advancing", self.move_index, math.sqrt(dist2), reach_radius))
        self.move_index = self.move_index + 1
        if self.move_index > #self.path_nodes then
            if self.forward_active then core.input.move_forward_stop(); self.forward_active = false end
            if self.turn_left_active then core.input.turn_left_stop(); self.turn_left_active = false end
            if self.turn_right_active then core.input.turn_right_stop(); self.turn_right_active = false end
            self.move_active = false
            dlog(self, "Path complete; movement finished")
            -- Auto-hide path when destination is reached
            self.path_nodes = nil
            self.path_poly_ids = nil
            if self.move_finish_cb then
                local cb = self.move_finish_cb
                self.move_finish_cb = nil
                cb(true)
            end
            return
        end
        tgt = self.path_nodes[self.move_index]
        dx = tgt.x - pos.x; dy = tgt.y - pos.y
        dist2 = vec_len2_xy(dx, dy)
    end

    -- Guidance probe to avoid immediate obstacles
    local dirx, diry = dx, dy
    local len = math.sqrt(dirx * dirx + diry * diry)
    if len > 1e-6 then dirx, diry = dirx / len, diry / len end
    local step = 1.0
    local best = { x = pos.x + dirx * step, y = pos.y + diry * step, z = pos.z }
    if not is_walkable_xy(self, best) then
        local lx, ly = -diry, dirx
        local try1 = { x = pos.x + (dirx * 0.7 + lx * 0.7) * step, y = pos.y + (diry * 0.7 + ly * 0.7) * step, z = pos.z }
        local try2 = { x = pos.x + (dirx * 0.7 - lx * 0.7) * step, y = pos.y + (diry * 0.7 - ly * 0.7) * step, z = pos.z }
        if is_walkable_xy(self, try1) then best = try1 elseif is_walkable_xy(self, try2) then best = try2 end
    end

    -- Steering: prefer look_at if available; fallback to key turns
    -- Compute desired direction towards target node (stabilizes key-turn steering)
    local ddx, ddy = (tgt.x - pos.x), (tgt.y - pos.y)
    local dlen = math.sqrt(ddx * ddx + ddy * ddy)
    local ndx, ndy = ddx, ddy
    if dlen > 1e-6 then ndx, ndy = ddx / dlen, ddy / dlen end
    -- Lua 5.1: math.atan(y, x) is the two-arg variant equivalent to atan2
    local heading = math.atan(ndy, ndx)
    local rot = player.get_rotation and player:get_rotation() or 0
    local err = heading - rot
    while err > math.pi do err = err - 2 * math.pi end
    while err < -math.pi do err = err + 2 * math.pi end
    local pdir = player.get_direction and player:get_direction() or nil
    local dot, cross = 0.0, 0.0
    if pdir then
        local pnx, pny = pdir.x, pdir.y
        local plen = math.sqrt(pnx * pnx + pny * pny)
        if plen > 1e-6 then pnx, pny = pnx / plen, pny / plen end
        dot = pnx * ndx + pny * ndy
        cross = pnx * ndy - pny * ndx
        -- Use robust signed angle between current facing and target direction
        err = math.atan(cross, dot)
    end
    local abs_err = math.abs(err)
    local tol = self.angle_tolerance or 0.06

    if (self.use_look_at and core.input and core.input.look_at) or (self.assist_look_at_enabled and core.input and core.input.look_at and (self.look_at_pulse_until_ms or 0) > (core.time() or 0)) then
        -- Face the next guidance point directly
        core.input.look_at(tgt)
        if self.turn_left_active then core.input.turn_left_stop(); self.turn_left_active = false end
        if self.turn_right_active then core.input.turn_right_stop(); self.turn_right_active = false end
        -- If heading error is small or we are using look_at, ensure forward starts
        if not self.forward_active then
            core.input.move_forward_start(); self.forward_active = true; self.last_forward_toggle_ms = core.time() or 0; dlog(self, "LookAt: initial FORWARD START")
        end
    else
        local tol_stop = tol
        local tol_start = tol + 0.03 -- hysteresis to prevent rapid toggling
        if abs_err <= tol_stop then
            if self.turn_left_active then core.input.turn_left_stop(); self.turn_left_active = false; dlog(self, "Turn left STOP") end
            if self.turn_right_active then core.input.turn_right_stop(); self.turn_right_active = false; dlog(self, "Turn right STOP") end
        elseif err >= tol_start then
            if self.turn_right_active then core.input.turn_right_stop(); self.turn_right_active = false; dlog(self, "Turn right STOP") end
            if not self.turn_left_active then core.input.turn_left_start(); self.turn_left_active = true; dlog(self, "Turn left START") end
        elseif err <= -tol_start then
            if self.turn_left_active then core.input.turn_left_stop(); self.turn_left_active = false; dlog(self, "Turn left STOP") end
            if not self.turn_right_active then core.input.turn_right_start(); self.turn_right_active = true; dlog(self, "Turn right START") end
        else
            -- within deadband: keep current turn state to stabilize
        end
    end

    -- Forward movement control
    local now_ms = core.time() or 0
    if (self.use_look_at and core.input and core.input.look_at) or (self.assist_look_at_enabled and core.input and core.input.look_at and (self.look_at_pulse_until_ms or 0) > now_ms) then
        -- With look_at steering, only (re)start forward when aligned enough towards the goal
        local pdir = player.get_direction and player:get_direction() or nil
        local dot = 0.0
        if pdir then
            local pnx, pny = pdir.x, pdir.y
            local plen = math.sqrt(pnx * pnx + pny * pny)
            if plen > 1e-6 then pnx, pny = pnx / plen, pny / plen end
            dot = pnx * ndx + pny * ndy
        end
        local need_align = dot < (self.desired_alignment_threshold or 0.85)
        -- Do not spam forward toggles; keep moving and adjust facing if misaligned
        if (not need_align) and (not self.forward_active) and (now_ms - (self.last_forward_toggle_ms or 0) >= (self.forward_restart_delay_ms or 120)) then
            core.input.move_forward_start(); self.forward_active = true; self.last_forward_toggle_ms = now_ms; dlog(self, string.format("LookAt: aligned dot=%.2f, FORWARD START", dot))
        end
        -- Optional: skip ahead if we drifted away from the current target but closer to the next one
        if self.path_nodes and self.move_index < #self.path_nodes then
            local nxt = self.path_nodes[self.move_index + 1]
            local d_curr2 = vec_len2_xy(tgt.x - pos.x, tgt.y - pos.y)
            local d_next2 = vec_len2_xy(nxt.x - pos.x, nxt.y - pos.y)
            if d_next2 + 0.5 < d_curr2 then
                dlog(self, string.format("Skip node: closer to next (curr=%.2f, next=%.2f)", math.sqrt(d_curr2), math.sqrt(d_next2)))
                self.move_index = self.move_index + 1
                tgt = nxt
                dx = tgt.x - pos.x; dy = tgt.y - pos.y
                dist2 = vec_len2_xy(dx, dy)
            end
        end
    else
        if is_mounted then
            local slow2 = (reach_radius + 0.8) ^ 2
            if dist2 <= slow2 and self.forward_active then
                core.input.move_forward_stop(); self.forward_active = false; self.last_forward_toggle_ms = now_ms; dlog(self, "Mounted: slow zone, FORWARD STOP")
            end
        end

        local hard = (is_mounted and (self.mounted_hard_turn_threshold or 1.5)) or (self.hard_turn_threshold or 0.9)
        local align_dot = (self.desired_alignment_threshold or 0.85)
        local start_dot = math.max(0.92, align_dot)
        if abs_err > hard or ((dot or 1.0) < 0.35) then
            if self.forward_active then core.input.move_forward_stop(); self.forward_active = false; self.last_forward_toggle_ms = now_ms; dlog(self, "Hard turn/misaligned, FORWARD STOP") end
        elseif ((dot or 0.0) >= start_dot) then
            if not self.forward_active and (now_ms - (self.last_forward_toggle_ms or 0) >= (self.forward_restart_delay_ms or 120)) then
                core.input.move_forward_start(); self.forward_active = true; self.last_forward_toggle_ms = now_ms; dlog(self, "FORWARD START")
            end
        else
            -- moderately aligned: keep current forward state
        end
    end

    -- Periodic movement diagnostics (once per second when debuglog_enabled)
    if self.debuglog_enabled then
        local last = self.last_movement_log_ms or 0
        local interval = self.debug_movement_log_interval_ms or 1000
        if (now_ms - last) >= interval then
            local rot_deg = (rot * 180.0 / math.pi)
            local head_deg = (heading * 180.0 / math.pi)
            local err_deg = (err * 180.0 / math.pi)
            local dist = math.sqrt(dist2)
            core.log(string.format(
                "[Nav] pos=(%.2f,%.2f,%.2f) tgt#%d=(%.2f,%.2f,%.2f) dist=%.2f reach=%.2f head=%.1f rot=%.1f err=%.1f dot=%.2f fwd=%s tl=%s tr=%s mounted=%s look_at=%s pulse=%s budget=%d/%d",
                pos.x, pos.y, pos.z,
                self.move_index, tgt.x, tgt.y, tgt.z,
                dist, reach_radius,
                head_deg, rot_deg, err_deg,
                dot or 0.0,
                tostring(self.forward_active), tostring(self.turn_left_active), tostring(self.turn_right_active),
                tostring(is_mounted), tostring(self.use_look_at), tostring((self.look_at_pulse_until_ms or 0) > now_ms),
                math.floor(self.look_at_budget_used_ms or 0), math.floor(self.look_at_budget_ms_per_sec or 0)
            ))
            self.last_movement_log_ms = now_ms
        end
    end
end

-- Build portal-center path between consecutive polygons in the id sequence
function TileManager:build_portal_center_path(poly_ids)
    local points = {}
    local function push_point(p)
        table.insert(points, { x = p.x, y = p.y, z = p.z })
    end

    local player = core.object_manager.get_local_player()
    if player then push_point(player:get_position()) end

    local id_to_poly = self.poly_lookup
    if not id_to_poly then return points end

    -- Helper to map quantized world coord key -> world coord for a polygon (works across tiles)
    local function get_coord_map(poly)
        local map = {}
        if not poly.coords then return map end
        local s = 0.5 -- 50cm bins (more tolerant across tile seams)
        for i = 1, #poly.coords do
            local c = poly.coords[i]
            if c then
                local kx = math.floor(c.x / s + 0.5)
                local ky = math.floor(c.y / s + 0.5)
                local key = tostring(kx) .. "," .. tostring(ky)
                map[key] = c
            end
        end
        return map
    end

    local function lerp_point(a, b, t)
        return { x = a.x + (b.x - a.x) * t, y = a.y + (b.y - a.y) * t, z = a.z + (b.z - a.z) * t }
    end

    for i = 1, #poly_ids - 1 do
        local a = id_to_poly[poly_ids[i]]
        local b = id_to_poly[poly_ids[i + 1]]
        if a and b then
            local mapA = get_coord_map(a)
            -- Find shared vertices using quantized world coordinates
            local shared = {}
    local s = 0.35
            for j = 1, #(b.coords or {}) do
                local cb = b.coords[j]
                if cb then
                    local kx = math.floor(cb.x / s + 0.5)
                    local ky = math.floor(cb.y / s + 0.5)
                    local key = tostring(kx) .. "," .. tostring(ky)
                    local pa = mapA[key]
                    if pa then
                        shared[#shared + 1] = { pos = { x = 0.5 * (pa.x + cb.x), y = 0.5 * (pa.y + cb.y), z = 0.5 * (pa.z + cb.z) } }
                        if #shared >= 2 then break end
                    end
                end
            end
            if #shared >= 2 then
                local p1 = shared[1].pos
                local p2 = shared[2].pos
                local mid = { x = (p1.x + p2.x) * 0.5, y = (p1.y + p2.y) * 0.5, z = (p1.z + p2.z) * 0.5 }
                -- Slightly bias the portal midpoint towards the next polygon center to act as a concrete position target
                local biased = lerp_point(mid, b.center, 0.15)
                push_point(biased)
            else
                -- Fallback to polygon center if no shared edge found
                push_point(a.center)
            end
        end
    end

    if self.saved_position then push_point(self.saved_position) end
    return points
end

-- Build a path using the funnel (string-pulling) algorithm across polygon portals
function TileManager:build_funnel_path(poly_ids, start_pos, end_pos)
    if not poly_ids or #poly_ids == 0 then return nil end
    local id_to_poly = self.poly_lookup or {}

    local function quant(v, s)
        local kx = math.floor((v.x or 0) / s + 0.5)
        local ky = math.floor((v.y or 0) / s + 0.5)
        return tostring(kx) .. "," .. tostring(ky)
    end
    local function build_portals()
        local portals = {}
        local s_match = 0.35
        for i = 1, #poly_ids - 1 do
            local a = id_to_poly[poly_ids[i]]
            local b = id_to_poly[poly_ids[i + 1]]
            if not a or not b or not a.coords or not b.coords then return nil end
            -- map of quantized coord -> vector from A
            local mapA = {}
            for _, ca in ipairs(a.coords) do mapA[quant(ca, s_match)] = ca end
            local shared = {}
            for _, cb in ipairs(b.coords) do
                local pa = mapA[quant(cb, s_match)]
                if pa then
                    shared[#shared + 1] = { a = pa, b = cb }
                    if #shared >= 2 then break end
                end
            end
            if #shared < 2 then return nil end
            -- order as left/right relative to the direction from a.center to b.center
            local p1 = shared[1].a
            local p2 = shared[2].a
            -- 2D orientation test
            local dx = (b.center.x or 0) - (a.center.x or 0)
            local dy = (b.center.y or 0) - (a.center.y or 0)
            local cross = dx * ((p2.y or 0) - (a.center.y or 0)) - dy * ((p2.x or 0) - (a.center.x or 0))
            local left_pt, right_pt
            if cross > 0 then
                left_pt, right_pt = p1, p2
            else
                left_pt, right_pt = p2, p1
            end
            portals[#portals + 1] = { left = left_pt, right = right_pt }
        end
        return portals
    end

    local function tri_area2(a, b, c)
        return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
    end
    local function string_pull(portals, startp, endp)
        local pts = {}
        local apex = { x = startp.x, y = startp.y, z = startp.z }
        local left = { x = startp.x, y = startp.y, z = startp.z }
        local right = { x = startp.x, y = startp.y, z = startp.z }
        local apex_index, left_index, right_index = 0, 0, 0
        table.insert(pts, { x = startp.x, y = startp.y, z = startp.z })

        for i = 1, #portals do
            local p = portals[i]
            local left_p = p.left
            local right_p = p.right

            -- update right vertex
            if tri_area2(apex, right, right_p) <= 0 then
                if apex.x == right.x and apex.y == right.y or tri_area2(apex, left, right_p) > 0 then
                    right = { x = right_p.x, y = right_p.y, z = right_p.z }
                    right_index = i
                else
                    -- tighten funnel at left
                    table.insert(pts, { x = left.x, y = left.y, z = left.z })
                    apex = { x = left.x, y = left.y, z = left.z }
                    apex_index = left_index
                    left = { x = apex.x, y = apex.y, z = apex.z }
                    right = { x = apex.x, y = apex.y, z = apex.z }
                    left_index = apex_index
                    right_index = apex_index
                    i = apex_index -- continue from the apex portal
                end
            end

            -- update left vertex
            if tri_area2(apex, left, left_p) >= 0 then
                if apex.x == left.x and apex.y == left.y or tri_area2(apex, right, left_p) < 0 then
                    left = { x = left_p.x, y = left_p.y, z = left_p.z }
                    left_index = i
                else
                    -- tighten funnel at right
                    table.insert(pts, { x = right.x, y = right.y, z = right.z })
                    apex = { x = right.x, y = right.y, z = right.z }
                    apex_index = right_index
                    left = { x = apex.x, y = apex.y, z = apex.z }
                    right = { x = apex.x, y = apex.y, z = apex.z }
                    left_index = apex_index
                    right_index = apex_index
                    i = apex_index
                end
            end
        end

        table.insert(pts, { x = endp.x, y = endp.y, z = endp.z })
        return pts
    end

    local portals = build_portals()
    if not portals or #portals == 0 then return nil end
    local path = string_pull(portals, start_pos or id_to_poly[poly_ids[1]].center, end_pos or id_to_poly[poly_ids[#poly_ids]].center)
    return path
end

-- Point-in-polygon (XY) test using ray casting; z ignored for stability
local function point_in_polygon_xy(pt, coords)
    if not coords or #coords < 3 then return false end
    local inside = false
    local x, y = pt.x or 0, pt.y or 0
    local n = #coords
    for i = 1, n do
        local j = (i % n) + 1
        local xi, yi = coords[i].x or 0, coords[i].y or 0
        local xj, yj = coords[j].x or 0, coords[j].y or 0
        local intersect = ((yi > y) ~= (yj > y)) and (x < ((xj - xi) * (y - yi) / (((yj - yi) ~= 0) and (yj - yi) or 1e-9) + xi))
        if intersect then inside = not inside end
    end
    return inside
end

-- Compute z on the polygon plane for XY position using first triangle fan
local function compute_plane_z(coords, x, y)
    if not coords or #coords < 3 then return nil end
    local a = coords[1]
    local b = coords[2]
    local c = coords[3]
    local ux, uy, uz = b.x - a.x, b.y - a.y, b.z - a.z
    local vx, vy, vz = c.x - a.x, c.y - a.y, c.z - a.z
    local nx, ny, nz = uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx
    if math.abs(nz) < 1e-9 then return a.z end
    -- Plane: n•(p - a) = 0 -> nx(x-ax) + ny(y-ay) + nz(z-az) = 0
    local z = a.z - (nx * (x - a.x) + ny * (y - a.y)) / nz
    return z
end

-- Clamping and Z projection removed: return original point unchanged
function clamp_point_to_polygon(p, poly)
    return p
end

-- Detail mesh z sampling: find the detail triangle under (x,y) and return barycentric z
function sample_z_from_detail(tile, poly, x, y)
    if not tile or not poly or not tile.detailMeshes or not tile.detailTris then return nil end
    local dmesh = tile.detailMeshes[poly.id]
    if not dmesh or dmesh.triCount == 0 then return nil end
    local triBase = dmesh.triBase or 0
    local vertBase = dmesh.vertBase or 0

    local function get_tri_vertex(idx)
        if idx < poly.vertCount then
            local base_idx = (poly.verts[idx + 1] or 0)
            local pos = base_idx * 3
            -- base_idx is zero-based in Detour; our vertices array is 1-based packed floats
            local vx = tile.vertices[pos + 1]
            local vy = tile.vertices[pos + 2]
            local vz = tile.vertices[pos + 3]
            local gx, gy, gz = toGameCoordinates(vx, vy, vz)
            return { x = gx, y = gy, z = gz }
        else
            local didx = vertBase + (idx - poly.vertCount)
            local dx, dy, dz = tile.getDetailVertWorld(didx + 1)
            if not dx or not dy or not dz then return nil end
            local gx, gy, gz = toGameCoordinates(dx, dy, dz)
            return { x = gx, y = gy, z = gz }
        end
    end

    local function barycentric(p, a, b, c)
        local v0x, v0y = b.x - a.x, b.y - a.y
        local v1x, v1y = c.x - a.x, c.y - a.y
        local v2x, v2y = x - a.x, y - a.y
        local d00 = v0x * v0x + v0y * v0y
        local d01 = v0x * v1x + v0y * v1y
        local d11 = v1x * v1x + v1y * v1y
        local d20 = v2x * v0x + v2y * v0y
        local d21 = v2x * v1x + v2y * v1y
        local denom = d00 * d11 - d01 * d01
        if math.abs(denom) < 1e-9 then return nil end
        local v = (d11 * d20 - d01 * d21) / denom
        local w = (d00 * d21 - d01 * d20) / denom
        local u = 1.0 - v - w
        if u >= -1e-4 and v >= -1e-4 and w >= -1e-4 then
            return u, v, w
        end
        return nil
    end

    for t = 0, (dmesh.triCount or 0) - 1 do
        local tri_i = (triBase or 0) + t + 1
        local tri = tile.detailTris[tri_i]
        if tri then
            local i0 = tri.v0 or tri.vertIndex0 or 0
            local i1 = tri.v1 or tri.vertIndex1 or 0
            local i2 = tri.v2 or tri.vertIndex2 or 0
            local a = get_tri_vertex(i0)
            local b = get_tri_vertex(i1)
            local c = get_tri_vertex(i2)
            if a and b and c then
                local u, v, w = barycentric({ x = x, y = y }, a, b, c)
                if u then
                    return u * a.z + v * b.z + w * c.z
                end
            end
        end
    end
    return nil
end

-- linter visibility
sample_z_from_detail = sample_z_from_detail

-- Choose best corridor polygon for a point based on XY inclusion and Z proximity
local function choose_owner_poly_for_point(p, ids, poly_lookup)
    -- Among overlapping polys that contain (x,y), choose the one whose center is closest in XY.
    -- This tends to match the corridor segment the node belongs to and avoids jumping layers.
    local best_poly, best_d2
    local x, y = p.x, p.y
    for _, pid in ipairs(ids or {}) do
        local poly = poly_lookup and poly_lookup[pid]
        if poly and poly.coords and #poly.coords >= 3 and point_in_polygon_xy(p, poly.coords) then
            local cx, cy = (poly.center and poly.center.x) or 0, (poly.center and poly.center.y) or 0
            local dx, dy = x - cx, y - cy
            local d2 = dx * dx + dy * dy
            if not best_d2 or d2 < best_d2 then
                best_d2 = d2
                best_poly = poly
            end
        end
    end
    return best_poly
end

-- Forward local refs so downstream code can see them for linter
clamp_point_to_polygon = clamp_point_to_polygon

-- Validate that all points of a path lie within the corridor polygons set
function path_inside_corridor(points, poly_ids, poly_lookup)
    if not points or #points == 0 then return false end
    for _, p in ipairs(points) do
        local ok = false
        for _, pid in ipairs(poly_ids or {}) do
            local poly = poly_lookup and poly_lookup[pid]
            if poly and poly.coords and #poly.coords >= 3 then
                if point_in_polygon_xy(p, poly.coords) then ok = true; break end
            end
        end
        if not ok then return false end
    end
    return true
end

-- Check whether a straight segment from a to b remains inside the corridor by sampling
local function segment_stays_inside_corridor(a, b, poly_ids, poly_lookup, step)
    local dx, dy = (b.x - a.x), (b.y - a.y)
    local dist = math.sqrt(dx * dx + dy * dy)
    local s = math.max(1, math.floor((dist / (step or 2.0)) + 0.5))
    for i = 0, s do
        local t = i / s
        local p = { x = a.x + dx * t, y = a.y + dy * t, z = a.z + (b.z - a.z) * t }
        local inside = false
        for _, pid in ipairs(poly_ids or {}) do
            local poly = poly_lookup and poly_lookup[pid]
            if poly and poly.coords and #poly.coords >= 3 then
                if point_in_polygon_xy(p, poly.coords) then inside = true; break end
            end
        end
        if not inside then return false end
    end
    return true
end

-- Aggressively straighten by connecting each node to the farthest visible future node
function visibility_straighten(points, poly_ids, poly_lookup, step)
    if not points or #points < 3 then return points end
    local result = {}
    local i = 1
    while i < #points do
        result[#result + 1] = points[i]
        local furthest = i + 1
        for j = #points, i + 1, -1 do
            if segment_stays_inside_corridor(points[i], points[j], poly_ids, poly_lookup, step) then
                furthest = j
                break
            end
        end
        if furthest <= i then
            break
        elseif furthest == i + 1 then
            i = i + 1
        else
            i = furthest
        end
    end
    if result[#result] ~= points[#points] then
        result[#result + 1] = points[#points]
    end
    return result
end

-- Utility: total 3D length of a point path
local function path_total_length(points)
    if not points or #points < 2 then return 0 end
    local sum = 0
    for i = 2, #points do
        local a = points[i - 1]
        local b = points[i]
        local dx = (b.x or 0) - (a.x or 0)
        local dy = (b.y or 0) - (a.y or 0)
        local dz = (b.z or 0) - (a.z or 0)
        sum = sum + math.sqrt(dx * dx + dy * dy + dz * dz)
    end
    return sum
end

function TileManager:draw_path_polygons()
    if not self.path_poly_ids or not self.poly_lookup then return end
    if self.path_graph_id and self.path_graph_id ~= self.graph_build_id then
        -- Corridor stale relative to current merged graph; skip drawing to avoid far-away artifacts
        return
    end
    local color = require('common/color')
    local vec3 = require('common/geometry/vector_3')
    local edge_col = color.new(80, 200, 255, 220)
    local fill_col = color.new(50, 120, 255, 60)
    for idx, pid in ipairs(self.path_poly_ids) do
        local poly = self.poly_lookup[pid]
        if poly and poly.coords and #poly.coords >= 3 then
            -- Triangle fan for a light fill
            local base = poly.coords[1]
            for i = 2, #poly.coords - 1 do
                local p1 = vec3.new(base.x, base.y, base.z + 0.02)
                local p2 = vec3.new(poly.coords[i].x, poly.coords[i].y, poly.coords[i].z + 0.02)
                local p3 = vec3.new(poly.coords[i+1].x, poly.coords[i+1].y, poly.coords[i+1].z + 0.02)
                core.graphics.triangle_3d_filled(p1, p2, p3, fill_col)
            end
            -- Edges
            for i = 1, #poly.coords do
                local a = poly.coords[i]
                local b = poly.coords[(i % #poly.coords) + 1]
                core.graphics.line_3d(vec3.new(a.x, a.y, a.z + 0.03), vec3.new(b.x, b.y, b.z + 0.03), edge_col, 2.0)
            end

            -- Draw neighboring polygons (prev and next) subtly to give corridor context
            local neighbor_ids = {}
            if idx > 1 then neighbor_ids[#neighbor_ids + 1] = self.path_poly_ids[idx - 1] end
            if idx < #self.path_poly_ids then neighbor_ids[#neighbor_ids + 1] = self.path_poly_ids[idx + 1] end
            local n_edge = color.new(80, 255, 160, 180)
            local n_fill = color.new(50, 255, 160, 40)
            for _, nid in ipairs(neighbor_ids) do
                local np = self.poly_lookup[nid]
                if np and np.coords and #np.coords >= 3 then
                    local b0 = np.coords[1]
                    for i = 2, #np.coords - 1 do
                        local p1 = vec3.new(b0.x, b0.y, b0.z + 0.01)
                        local p2 = vec3.new(np.coords[i].x, np.coords[i].y, np.coords[i].z + 0.01)
                        local p3 = vec3.new(np.coords[i+1].x, np.coords[i+1].y, np.coords[i+1].z + 0.01)
                        core.graphics.triangle_3d_filled(p1, p2, p3, n_fill)
                    end
                    for i = 1, #np.coords do
                        local a2 = np.coords[i]
                        local b2 = np.coords[(i % #np.coords) + 1]
                        core.graphics.line_3d(vec3.new(a2.x, a2.y, a2.z + 0.02), vec3.new(b2.x, b2.y, b2.z + 0.02), n_edge, 1.5)
                    end
                end
            end
        end
    end
end

-- Draw only the corridor polygons in 3 nested alpha levels:
-- - Dark transparent green for the path polygons
-- - Normal transparent green for their immediate neighbors
-- - Very transparent green for neighbors of those
-- draw_path_corridor_layers removed (only the real path is drawn now)

-- Utility: squared distance from point C to segment AB (ignore z for stability)
local function dist2_point_to_segment_xy(a, b, c)
    local ax, ay = a.x, a.y
    local bx, by = b.x, b.y
    local cx, cy = c.x, c.y
    local abx, aby = bx - ax, by - ay
    local acx, acy = cx - ax, cy - ay
    local ab2 = abx * abx + aby * aby
    if ab2 <= 1e-6 then
        local dx, dy = cx - ax, cy - ay
        return dx * dx + dy * dy
    end
    local t = (acx * abx + acy * aby) / ab2
    if t < 0 then t = 0 elseif t > 1 then t = 1 end
    local px, py = ax + t * abx, ay + t * aby
    local dx, dy = cx - px, cy - py
    return dx * dx + dy * dy
end

-- Simplify using RDP-like criterion on XY plane
function TileManager:simplify_path(nodes, tol)
    if not nodes or #nodes <= 2 then return nodes end
    local tol2 = (tol or 1.0) * (tol or 1.0)
    local result = {}
    local function simplify_section(i1, i2)
        local max_d2, idx = 0.0, -1
        local a, b = nodes[i1], nodes[i2]
        for i = i1 + 1, i2 - 1 do
            local d2 = dist2_point_to_segment_xy(a, b, nodes[i])
            if d2 > max_d2 then max_d2 = d2; idx = i end
        end
        if max_d2 > tol2 and idx > 0 then
            simplify_section(i1, idx)
            simplify_section(idx, i2)
        else
            table.insert(result, a)
        end
    end
    simplify_section(1, #nodes)
    table.insert(result, nodes[#nodes])
    return result
end

-- Chaikin corner-cutting smoothing
function TileManager:chaikin_smooth(nodes, iterations)
    if not nodes or #nodes <= 2 then return nodes end
    local iters = math.max(0, math.floor(iterations or 0))
    local function lerp(a, b, t)
        return { x = a.x + (b.x - a.x) * t, y = a.y + (b.y - a.y) * t, z = a.z + (b.z - a.z) * t }
    end
    local pts = nodes
    for _ = 1, iters do
        local new_pts = {}
        new_pts[1] = pts[1]
        for i = 1, #pts - 1 do
            local a, b = pts[i], pts[i + 1]
            local q = lerp(a, b, 0.25)
            local r = lerp(a, b, 0.75)
            table.insert(new_pts, q)
            table.insert(new_pts, r)
        end
        table.insert(new_pts, pts[#pts])
        pts = new_pts
    end
    return pts
end

-- Add arc turns to respect a minimum turning radius (vehicle-like smoothing)
function TileManager:apply_turn_radius(nodes, radius, segments)
    if not nodes or #nodes < 3 then return nodes end
    local r = math.max(0.1, radius or 2.5)
    local segs = math.max(2, math.floor(segments or 6))

    local function norm(vx, vy)
        local l = math.sqrt(vx * vx + vy * vy)
        if l < 1e-6 then return 0, 0, 0 end
        return vx / l, vy / l, l
    end

    local function bezier(p0, p1, p2, t)
        local u = 1 - t
        return {
            x = u * u * p0.x + 2 * u * t * p1.x + t * t * p2.x,
            y = u * u * p0.y + 2 * u * t * p1.y + t * t * p2.y,
            z = u * u * p0.z + 2 * u * t * p1.z + t * t * p2.z,
        }
    end

    local out = { nodes[1] }
    for i = 2, #nodes - 1 do
        local a = nodes[i - 1]
        local b = nodes[i]
        local c = nodes[i + 1]
        local ux, uy, la = norm(b.x - a.x, b.y - a.y)
        local vx, vy, lb = norm(c.x - b.x, c.y - b.y)
        -- If nearly colinear, keep the original corner
        local dot = ux * vx + uy * vy
        if dot > 0.999 or dot < -0.999 then
            table.insert(out, b)
        else
            -- Limit offset by available segment lengths
            local d = math.min(r, la * 0.5, lb * 0.5)
            local entry = { x = b.x - ux * d, y = b.y - uy * d, z = b.z }
            local exit  = { x = b.x + vx * d, y = b.y + vy * d, z = b.z }
            -- Control on the angle bisector (outwards)
            local bx, by = ux + vx, uy + vy
            local bxn, byn = norm(bx, by)
            local ctrl = { x = b.x + bxn * d, y = b.y + byn * d, z = b.z }

            table.insert(out, entry)
            for s = 1, segs - 1 do
                local t = s / segs
                table.insert(out, bezier(entry, ctrl, exit, t))
            end
            table.insert(out, exit)
        end
    end
    table.insert(out, nodes[#nodes])
    return out
end

-- Debug visualization functions
function TileManager:render_menu()
    if not self.menu_inited then
        self.menu_tree = core.menu.tree_node()
        self.btn_save = core.menu.button("lx_nav_save_pos")
        self.btn_path = core.menu.button("lx_nav_make_path")
        self.btn_move = core.menu.button("lx_nav_move_to_saved")
        self.cb_smooth = core.menu.checkbox(true, "lx_nav_smooth_enabled")
        
        self.cb_draw_mesh = core.menu.checkbox(false, "lx_nav_draw_mesh")
        self.cb_draw_path_polys = core.menu.checkbox(false, "lx_nav_draw_path_polys")
        self.menu_inited = true
    end

    self.menu_tree:render("Lx_Nav", function()
        -- Draw mesh toggle
        self.cb_draw_mesh:render("Draw mesh")
        self.draw_navmesh_enabled = self.cb_draw_mesh:get_state()
        self.cb_draw_path_polys:render("Draw path polys")
        self.draw_path_polygons_enabled = self.cb_draw_path_polys:get_state()

        -- Save position button
        self.btn_save:render("Save position")
        if self.btn_save:is_clicked() then
            local player = core.object_manager.get_local_player()
            if player then
                self.saved_position = player:get_position()
                dlog(self, "Saved position: (" .. string.format("%.1f,%.1f,%.1f", self.saved_position.x, self.saved_position.y, self.saved_position.z) .. ")")
            end
        end

        -- Path button
        self.btn_path:render("Path to saved")
        if self.btn_path:is_clicked() then
            self:compute_path_to_saved()
        end

        -- Move button
        self.btn_move:render("Move to saved")
        if self.btn_move:is_clicked() then
            self:start_move_to_saved()
        end

        -- Slope controls removed (using walkable filtering only)

        -- Smoothing controls
        self.cb_smooth:render("Smooth path")
        self.smooth_path_enabled = self.cb_smooth:get_state()
        -- Fixed smoothing: iterations=2, simplify tol=1.8

        -- Cost biases (clearance is fixed internally)
        
    end)
end

function TileManager:draw_path()
    if not self.path_nodes or #self.path_nodes < 2 then return end
    local color = require('common/color')
    local vec3 = require('common/geometry/vector_3')
    local path_col = color.new(50, 150, 255, 255)
    for i = 1, #self.path_nodes - 1 do
        local p1 = self.path_nodes[i]
        local p2 = self.path_nodes[i + 1]
        core.graphics.line_3d(vec3.new(p1.x, p1.y, p1.z), vec3.new(p2.x, p2.y, p2.z), path_col, 3.0)
    end

    -- Guidance direction: draw short forward vector from player towards the next clear point
    local player = core.object_manager.get_local_player()
    if not player then return end
    local pos = player:get_position()
    local target = self.path_nodes[math.min(#self.path_nodes, 2)] or self.path_nodes[1]
    if not target then return end

    -- Sample forward direction with simple obstacle-aware probe on XY using nav polys
    local sample = { x = pos.x, y = pos.y, z = pos.z }
    local dirx, diry = target.x - pos.x, target.y - pos.y
    local len = math.sqrt(dirx * dirx + diry * diry)
    if len > 1e-3 then
        dirx, diry = dirx / len, diry / len
        local step = 1.0
        local best = { x = pos.x + dirx * step, y = pos.y + diry * step, z = pos.z }
        local ok = is_walkable_xy(self, best)
        if not ok then
            -- try slight left/right offsets to avoid immediate obstacle
            local lx, ly = -diry, dirx
            local try1 = { x = pos.x + (dirx * 0.7 + lx * 0.7) * step, y = pos.y + (diry * 0.7 + ly * 0.7) * step, z = pos.z }
            local try2 = { x = pos.x + (dirx * 0.7 - lx * 0.7) * step, y = pos.y + (diry * 0.7 - ly * 0.7) * step, z = pos.z }
            if is_walkable_xy(self, try1) then best = try1 elseif is_walkable_xy(self, try2) then best = try2 end
        end
        if self.show_path then
            local color2 = color.new(0, 255, 180, 220)
            core.graphics.line_3d(vec3.new(pos.x, pos.y, pos.z), vec3.new(best.x, best.y, best.z), color2, 4.0)
        end
    end
    -- Removed polygon highlighting next to player to only draw the real path
end
function TileManager:draw_debug_tile_boundaries()
    if not self.current_tile or not self.debug_enabled then
        return
    end

    local vec3 = require('common/geometry/vector_3')
    local color = require('common/color')

    -- Calculate tile boundaries in world coordinates
    local tile_x, tile_y = self.current_tile.x, self.current_tile.y
    local tile_size = mesh_helper.tile_size
    local half_world = mesh_helper.HALF_WORLD

    -- Calculate world coordinates for tile corners
    local min_x = half_world - (tile_x + 1) * tile_size
    local max_x = half_world - tile_x * tile_size
    local min_y = half_world - (tile_y + 1) * tile_size
    local max_y = half_world - tile_y * tile_size

    -- Create corner points at different heights for a 3D effect
    local height_offset = 5.0
    local corners_bottom = {
        vec3.new(min_x, min_y, -height_offset), -- bottom-left
        vec3.new(max_x, min_y, -height_offset), -- bottom-right
        vec3.new(max_x, max_y, -height_offset), -- top-right
        vec3.new(min_x, max_y, -height_offset)  -- top-left
    }

    local corners_top = {
        vec3.new(min_x, min_y, height_offset), -- bottom-left
        vec3.new(max_x, min_y, height_offset), -- bottom-right
        vec3.new(max_x, max_y, height_offset), -- top-right
        vec3.new(min_x, max_y, height_offset)  -- top-left
    }

    -- Draw tile boundary as a 3D rectangle with gradient colors
    local bottom_color = color.new(255, 255, 0, 150) -- Yellow with transparency
    local top_color = color.new(255, 100, 0, 200)    -- Orange with more opacity

    -- Draw bottom and top edges
    for i = 1, 4 do
        local p1_bottom = corners_bottom[i]
        local p2_bottom = corners_bottom[i % 4 + 1]
        local p1_top = corners_top[i]
        local p2_top = corners_top[i % 4 + 1]

        -- Bottom edges
        core.graphics.line_3d(p1_bottom, p2_bottom, bottom_color, 3.0)
        -- Top edges
        core.graphics.line_3d(p1_top, p2_top, top_color, 3.0)
        -- Vertical edges connecting top and bottom
        core.graphics.line_3d(p1_bottom, p1_top, color.new(255, 200, 0, 180), 2.0)
    end

    -- Draw filled rectangles for the sides to give a 3D box appearance
    for i = 1, 4 do
        local p1_bottom = corners_bottom[i]
        local p2_bottom = corners_bottom[i % 4 + 1]
        local p1_top = corners_top[i]
        local p2_top = corners_top[i % 4 + 1]

        -- Create side rectangles
        local side_color = color.new(255, 150, 0, 80) -- Semi-transparent orange
        core.graphics.triangle_3d_filled(p1_bottom, p2_bottom, p1_top, side_color)
        core.graphics.triangle_3d_filled(p2_bottom, p2_top, p1_top, side_color)
    end

    -- Draw tile center marker with gradient
    local center_x = (min_x + max_x) / 2
    local center_y = (min_y + max_y) / 2
    local center_bottom = vec3.new(center_x, center_y, -height_offset)
    local center_top = vec3.new(center_x, center_y, height_offset + 5)

    -- Draw a gradient cylinder-like marker
    core.graphics.circle_3d_filled(center_bottom, 3.0, color.new(255, 255, 0, 150))
    core.graphics.circle_3d_filled(center_top, 3.0, color.new(255, 100, 0, 200))
    core.graphics.line_3d(center_bottom, center_top, color.new(255, 200, 0, 180), 2.0)

    -- Add tile coordinate text with background
    local text_pos = vec3.new(center_x, center_y, height_offset + 10)
    core.graphics.text_3d(string.format("Tile: %d,%d", tile_x, tile_y), text_pos, 20, color.new(255, 255, 255, 255), true)

    -- Add additional info text
    local info_pos = vec3.new(center_x, center_y, height_offset + 5)
    core.graphics.text_3d(string.format("Size: %.1fm", tile_size), info_pos, 16, color.new(200, 200, 200, 255), true)
end

function TileManager:draw_debug_vertices()
    if not self.navmesh or not self.debug_enabled then
        return
    end

    local vec3 = require('common/geometry/vector_3')
    local color = require('common/color')

    -- Draw spheres at each vertex position
    for i, vertex in ipairs(self.navmesh.vertices) do
        local pos = vec3.new(vertex.x, vertex.y, vertex.z)

        -- Color based on height (z-coordinate)
        local height_ratio = (vertex.z + 100) / 200 -- Normalize height for coloring
        height_ratio = math.max(0, math.min(1, height_ratio))
        local r = math.floor(255 * height_ratio)
        local g = math.floor(255 * (1 - height_ratio))
        local b = 100

        core.graphics.circle_3d_filled(pos, 0.5, color.new(r, g, b, 200))

        -- Add vertex index text
        local text_pos = vec3.new(vertex.x, vertex.y, vertex.z + 1.0)
        core.graphics.text_3d(string.format("V%d", i), text_pos, 16, color.new(255, 255, 255, 255))
    end
end

function TileManager:draw_debug_coordinate_system()
    if not self.debug_enabled then
        return
    end

    local vec3 = require('common/geometry/vector_3')
    local color = require('common/color')

    -- Get player position for reference
    local player = core.object_manager.get_local_player()
    if not player then return end

    local player_pos = player:get_position()

    -- Draw world origin (0,0,0)
    local origin = vec3.new(0, 0, 0)
    core.graphics.circle_3d_filled(origin, 1.0, color.new(255, 0, 0, 255))
    core.graphics.text_3d("WORLD ORIGIN", vec3.new(0, 0, 2), 16, color.new(255, 0, 0, 255))

    -- Draw coordinate axes
    local axis_length = 20.0
    core.graphics.line_3d(origin, vec3.new(axis_length, 0, 0), color.new(255, 0, 0, 255)) -- X axis (red)
    core.graphics.line_3d(origin, vec3.new(0, axis_length, 0), color.new(0, 255, 0, 255)) -- Y axis (green)
    core.graphics.line_3d(origin, vec3.new(0, 0, axis_length), color.new(0, 0, 255, 255)) -- Z axis (blue)

    -- Draw player position marker
    core.graphics.circle_3d_filled(player_pos, 1.5, color.new(0, 255, 255, 255))
    core.graphics.text_3d(string.format("PLAYER: %.1f, %.1f, %.1f", player_pos.x, player_pos.y, player_pos.z),
        vec3.new(player_pos.x, player_pos.y, player_pos.z + 3),
        16, color.new(0, 255, 255, 255))
end

function TileManager:draw_debug_polygon_centers()
    if not self.current_polygons or not self.debug_enabled then
        return
    end

    local vec3 = require('common/geometry/vector_3')
    local color = require('common/color')

    -- Draw polygon centers with position labels
    for _, poly in ipairs(self.current_polygons) do
        local center_pos = vec3.new(poly.center.x, poly.center.y, poly.center.z)

        -- Draw center marker
        core.graphics.circle_3d_filled(center_pos, 1.0, color.new(255, 0, 255, 200))

        -- Add position text
        local text_pos = vec3.new(poly.center.x, poly.center.y, poly.center.z + 2.0)
        core.graphics.text_3d(string.format("P: %.1f, %.1f, %.1f",
                poly.center.x, poly.center.y, poly.center.z),
            text_pos, 16, color.new(255, 0, 255, 255))
    end
end

function TileManager:draw_debug_grid()
    if not self.debug_enabled then
        return
    end

    local vec3 = require('common/geometry/vector_3')
    local color = require('common/color')

    local tile_size = mesh_helper.tile_size
    local half_world = mesh_helper.HALF_WORLD

    -- Draw grid lines for nearby tiles
    local player = core.object_manager.get_local_player()
    if not player then return end

    local player_pos = player:get_position()
    local player_tile_x, player_tile_y = mesh_helper.get_tile_coordinates(player_pos.x, player_pos.y)

    -- Draw grid around player (3x3 tiles)
    for dx = -1, 1 do
        for dy = -1, 1 do
            local tile_x = player_tile_x + dx
            local tile_y = player_tile_y + dy

            if tile_x >= 0 and tile_x <= 63 and tile_y >= 0 and tile_y <= 63 then
                local min_x = half_world - (tile_x + 1) * tile_size
                local max_x = half_world - tile_x * tile_size
                local min_y = half_world - (tile_y + 1) * tile_size
                local max_y = half_world - tile_y * tile_size

                -- Draw grid cell boundaries
                local corners = {
                    vec3.new(min_x, min_y, 0),
                    vec3.new(max_x, min_y, 0),
                    vec3.new(max_x, max_y, 0),
                    vec3.new(min_x, max_y, 0)
                }

                local grid_color = color.new(100, 100, 100, 100) -- Dim gray for grid
                for i = 1, 4 do
                    local p1 = corners[i]
                    local p2 = corners[i % 4 + 1]
                    core.graphics.line_3d(p1, p2, grid_color)
                end
            end
        end
    end
end

-- Draw walkable polygons
function TileManager:draw_walkable_polygons()
    if not self.debug_enabled then
        return
    end

    local vec3 = require('common/geometry/vector_3')
    local color = require('common/color')

    -- Colors
    local default_fill = color.new(255, 255, 255, 128)   -- white, ~50% alpha
    local default_edge = color.new(255, 255, 255, 128)
    local water_fill   = color.new(100, 180, 255, 60)    -- light blue, even more transparent
    local water_edge   = color.new(120, 190, 255, 80)
    local ground11_fill = color.new(170, 170, 170, 80)   -- area 11: gray, more transparent
    local ground11_edge = color.new(180, 180, 180, 100)
    local edge_width = 3.0

    -- Helper to draw a polygon list against a given tile_data
    local function draw_poly_list(polys, tile_data)
        for _, poly in ipairs(polys or {}) do
            local poly_type = poly.areaAndtype and (math.floor(poly.areaAndtype / 64) % 4) or 0
            if poly_type == 0 and poly.vertices and #poly.vertices >= 3 then
                local points = {}
                for _, vertex_idx in ipairs(poly.vertices) do
                    local vertex_pos = (vertex_idx - 1) * 3 + 1
                    if tile_data and (vertex_pos + 2) <= #tile_data.vertices then
                        local mesh_x = tile_data.vertices[vertex_pos]
                        local mesh_y = tile_data.vertices[vertex_pos + 1]
                        local mesh_z = tile_data.vertices[vertex_pos + 2]
                        if mesh_x and mesh_y and mesh_z then
                            local gx, gy, gz = toGameCoordinates(mesh_x, mesh_y, mesh_z)
                            table.insert(points, vec3.new(gx, gy, gz))
                        end
                    end
                end
                if #points >= 3 then
                    local base = points[1]
                    local base_off = vec3.new(base.x, base.y, base.z + 0.02)
                    -- Choose fill color by area (9 = water, 11 = walkable gray)
                    local area_id = poly.areaAndtype and (poly.areaAndtype % 64) or 0
                    local fill_col = (area_id == 9) and water_fill or ((area_id == 11) and ground11_fill or default_fill)
                    for i = 2, #points - 1 do
                        local p2 = points[i]
                        local p3 = points[i + 1]
                        local p2_off = vec3.new(p2.x, p2.y, p2.z + 0.02)
                        local p3_off = vec3.new(p3.x, p3.y, p3.z + 0.02)
                        core.graphics.triangle_3d_filled(base_off, p2_off, p3_off, fill_col)
                    end
                end
                -- Skip edge drawing to reduce visual clutter
                -- Draw area id number at center for non-water, non-11 polygons
                do
                    local area_id = poly.areaAndtype and (poly.areaAndtype % 64) or 0
                    if area_id ~= 9 and area_id ~= 11 then
                        local cx = (poly.center and poly.center.x) or 0
                        local cy = (poly.center and poly.center.y) or 0
                        local cz = (poly.center and poly.center.z) or 0
                        local text_pos = vec3.new(cx, cy, cz + 0.3)
                        core.graphics.text_3d(string.format("%d", area_id), text_pos, 12, color.new(255, 255, 255, 220))
                    end
                end
            end
        end
    end

    if not self.current_polygons or not self.current_tile_data then return end
    draw_poly_list(self.current_polygons, self.current_tile_data)
end

-- Toggle debug visualization
function TileManager:toggle_debug()
    self.debug_enabled = not self.debug_enabled
    dlog(self, "Debug visualization: " .. (self.debug_enabled and "ENABLED" or "DISABLED"))
end

-- Toggle enhanced visualization features
function TileManager:toggle_enhanced_visualization()
    self.enhanced_visualization = not self.enhanced_visualization
    dlog(self, "Enhanced visualization: " .. (self.enhanced_visualization and "ENABLED" or "DISABLED"))

    -- If enabling enhanced visualization, also enable debug
    if self.enhanced_visualization then
        self.debug_enabled = true
    end
end

-- Example function to draw the navmesh with debug info
function TileManager:draw_navmesh()
    -- Check if we have a navmesh to draw
    if not self.navmesh or not self.draw_navmesh_enabled then
        return
    end

    -- Import required modules
    local vec3 = require('common/geometry/vector_3')
    local color = require('common/color')

    -- Get player position for distance-based optimizations
    local player = core.object_manager.get_local_player()
    if not player then return end
    local player_pos = player:get_position()

    -- If configured to draw polygons, render those and skip raw triangles
    if self.draw_polygons then
        self:draw_walkable_polygons()
        return
    end

    -- Draw each triangle in the navmesh as filled triangles with edges
    if self.navmesh.triangles and self.navmesh.vertices then
        dlog(self, "=== DRAWING NAVMESH ===")
        dlog(self, "Player position: (" .. string.format("%.1f,%.1f,%.1f", player_pos.x, player_pos.y, player_pos.z) .. ")")
        dlog(self, "Total triangles to process: " .. #self.navmesh.triangles)

        -- Performance optimization: Limit the number of triangles drawn per frame
        local max_triangles_per_frame = 500
        local triangle_count = 0
        local triangles_in_range = 0

        for tri_idx, triangle in ipairs(self.navmesh.triangles) do
            -- Early exit if we've drawn too many triangles this frame
            if triangle_count >= max_triangles_per_frame then
                break
            end

            -- Get the three vertices of the triangle
            local v1 = self.navmesh.vertices[triangle[1]]
            local v2 = self.navmesh.vertices[triangle[2]]
            local v3 = self.navmesh.vertices[triangle[3]]

            if v1 and v2 and v3 then
                -- Create vec3 objects for the vertices
                local p1 = vec3.new(v1.x, v1.y, v1.z)
                local p2 = vec3.new(v2.x, v2.y, v2.z)
                local p3 = vec3.new(v3.x, v3.y, v3.z)

                -- Performance optimization: Skip triangles that are too far from the player
                local center_x = (v1.x + v2.x + v3.x) / 3
                local center_y = (v1.y + v2.y + v3.y) / 3
                local center_z = (v1.z + v2.z + v3.z) / 3
                local distance_sq = (center_x - player_pos.x) ^ 2 + (center_y - player_pos.y) ^ 2 +
                (center_z - player_pos.z) ^ 2

                -- Only draw triangles within 100 yards of the player
                if distance_sq <= 10000 then
                    triangles_in_range = triangles_in_range + 1
                    triangle_count = triangle_count + 1

                    -- Debug: Log first few triangles being drawn
                    if triangles_in_range <= 5 then
                        core.log("Drawing triangle " .. tri_idx .. " (in-range #" .. triangles_in_range .. "):")
                        core.log("  Center: (" ..
                        string.format("%.1f,%.1f,%.1f", center_x, center_y, center_z) ..
                        ") distance: " .. string.format("%.1f", math.sqrt(distance_sq)))
                        core.log("  v1: (" .. string.format("%.1f,%.1f,%.1f", v1.x, v1.y, v1.z) .. ")")
                        core.log("  v2: (" .. string.format("%.1f,%.1f,%.1f", v2.x, v2.y, v2.z) .. ")")
                        core.log("  v3: (" .. string.format("%.1f,%.1f,%.1f", v3.x, v3.y, v3.z) .. ")")
                    end

                    -- Calculate average height for coloring
                    local avg_height = (v1.z + v2.z + v3.z) / 3

                    -- Create height-based color (blue for low, red for high) with gradient effect
                    local height_ratio = (avg_height + 50) / 100 -- Normalize height for coloring
                    height_ratio = math.max(0, math.min(1, height_ratio))

                    -- Create gradient colors for each vertex based on their individual heights
                    local function get_vertex_color(height)
                        local h_ratio = (height + 50) / 100
                        h_ratio = math.max(0, math.min(1, h_ratio))
                        local r = math.floor(255 * h_ratio)
                        local g = math.floor(100 * (1 - math.abs(h_ratio - 0.5) * 2))
                        local b = math.floor(255 * (1 - h_ratio))
                        -- Ensure color values are within valid range
                        r = math.max(0, math.min(255, r))
                        g = math.max(0, math.min(255, g))
                        b = math.max(0, math.min(255, b))
                        return color.new(r, g, b, 180) -- Semi-transparent
                    end

                    local color1 = get_vertex_color(v1.z)
                    local color2 = get_vertex_color(v2.z)
                    local color3 = get_vertex_color(v3.z)

                    -- Ensure color objects are valid
                    if not color1 or not color2 or not color3 then
                        -- Fallback to neutral color if there's an issue
                        local fb_r, fb_g, fb_b = 128, 128, 128
                        color1 = color1 or color.new(fb_r, fb_g, fb_b, 180)
                        color2 = color2 or color.new(fb_r, fb_g, fb_b, 180)
                        color3 = color3 or color.new(fb_r, fb_g, fb_b, 180)
                    end

                    -- Draw filled triangle with gradient effect using multiple layers
                    -- First draw with average color as base
                    local r = math.floor(255 * height_ratio)
                    local g = math.floor(100 * (1 - math.abs(height_ratio - 0.5) * 2))
                    local b = math.floor(255 * (1 - height_ratio))
                    local base_color = color.new(r, g, b, 80) -- More transparent base
                    core.graphics.triangle_3d_filled(p1, p2, p3, base_color)

                    -- Draw gradient effect by drawing multiple triangles with varying colors
                    -- This creates a pseudo-gradient effect by layering
                    for i = 1, 3 do
                        local alpha = 60 + i * 20
                        -- Access color components correctly with fallback
                        local r1, g1, b1 = color1.r or 0, color1.g or 0, color1.b or 0
                        local r2, g2, b2 = color2.r or 0, color2.g or 0, color2.b or 0
                        local r3, g3, b3 = color3.r or 0, color3.g or 0, color3.b or 0

                        local r_avg = math.floor((r1 + r2 + r3) / 3)
                        local g_avg = math.floor((g1 + g2 + g3) / 3)
                        local b_avg = math.floor((b1 + b2 + b3) / 3)

                        -- Ensure color values are within valid range
                        r_avg = math.max(0, math.min(255, r_avg))
                        g_avg = math.max(0, math.min(255, g_avg))
                        b_avg = math.max(0, math.min(255, b_avg))

                        local layer_color = color.new(r_avg, g_avg, b_avg, alpha)
                        -- Slightly offset each layer to create depth effect
                        local offset = (i - 2) * 0.1
                        local p1_offset = vec3.new(v1.x, v1.y, v1.z + offset)
                        local p2_offset = vec3.new(v2.x, v2.y, v2.z + offset)
                        local p3_offset = vec3.new(v3.x, v3.y, v3.z + offset)
                        core.graphics.triangle_3d_filled(p1_offset, p2_offset, p3_offset, layer_color)
                    end

                    -- Draw triangle edges with brighter color
                    local edge_color = color.new(math.min(255, r + 50), math.min(255, g + 50), math.min(255, b + 50), 255)
                    --core.graphics.line_3d(p1, p2, edge_color, 2.5, 2.5, true)
                    --core.graphics.line_3d(p2, p3, edge_color, 2.5, 2.5, true)
                    --core.graphics.line_3d(p3, p1, edge_color, 2.5, 2.5, true)

                    -- Add subtle glow effect to edges
                    core.graphics.line_3d(p1, p2, color.new(255, 255, 255, 100), 4.0, 1.5, true)
                    core.graphics.line_3d(p2, p3, color.new(255, 255, 255, 100), 4.0, 1.5, true)
                    core.graphics.line_3d(p3, p1, color.new(255, 255, 255, 100), 4.0, 1.5, true)

                    -- Calculate and draw normal vector for the triangle (only for close triangles)
                    if self.debug_enabled and self.enhanced_visualization and distance_sq <= 2500 then -- Only within 50 yards
                        -- Calculate triangle normal
                        local edge1 = vec3.new(p2.x - p1.x, p2.y - p1.y, p2.z - p1.z)
                        local edge2 = vec3.new(p3.x - p1.x, p3.y - p1.y, p3.z - p1.z)

                        -- Cross product to get normal
                        local normal = vec3.new(
                            edge1.y * edge2.z - edge1.z * edge2.y,
                            edge1.z * edge2.x - edge1.x * edge2.z,
                            edge1.x * edge2.y - edge1.y * edge2.x
                        )

                        -- Normalize the normal vector
                        local length = math.sqrt(normal.x * normal.x + normal.y * normal.y + normal.z * normal.z)
                        if length > 0 then
                            normal.x = normal.x / length
                            normal.y = normal.y / length
                            normal.z = normal.z / length

                            -- Calculate triangle center
                            local center = vec3.new(
                                (p1.x + p2.x + p3.x) / 3,
                                (p1.y + p2.y + p3.y) / 3,
                                (p1.z + p2.z + p3.z) / 3
                            )

                            -- Draw normal vector
                            local normal_end = vec3.new(
                                center.x + normal.x * 3.0,
                                center.y + normal.y * 3.0,
                                center.z + normal.z * 3.0
                            )

                            core.graphics.line_3d(center, normal_end, color.new(0, 255, 0, 255), 2.0)
                            core.graphics.circle_3d_filled(normal_end, 0.5, color.new(0, 255, 0, 255))
                        end
                    end
                end
            end
        end

        core.log("=== DRAWING COMPLETE ===")
        core.log("Triangles in range: " .. triangles_in_range .. " / " .. #self.navmesh.triangles)
        core.log("Triangles drawn: " .. triangle_count)

        -- If we hit the triangle limit, show a notification
        if triangle_count >= max_triangles_per_frame then
            core.graphics.add_notification(
                "navmesh_limit",
                "Performance Warning",
                string.format("Limited to %d triangles per frame", max_triangles_per_frame),
                3000, -- 3 seconds
                color.new(255, 255, 0, 255)
            )
        end
    end

    -- Draw vertices as small spheres (with performance optimization)
    if self.debug_enabled and self.enhanced_visualization and self.navmesh.vertices then
        local vertex_count = 0
        local max_vertices_per_frame = 200

        for i, vertex in ipairs(self.navmesh.vertices) do
            -- Early exit if we've drawn too many vertices this frame
            if vertex_count >= max_vertices_per_frame then
                break
            end

            -- Performance optimization: Skip vertices that are too far from the player
            local distance_sq = (vertex.x - player_pos.x) ^ 2 + (vertex.y - player_pos.y) ^ 2 +
            (vertex.z - player_pos.z) ^ 2
            if distance_sq <= 10000 then -- Only within 100 yards
                vertex_count = vertex_count + 1

                local pos = vec3.new(vertex.x, vertex.y, vertex.z)

                -- Color based on height (z-coordinate)
                local height_ratio = (vertex.z + 50) / 100 -- Normalize height for coloring
                height_ratio = math.max(0, math.min(1, height_ratio))
                local r = math.floor(255 * height_ratio)
                local g = math.floor(255 * (1 - height_ratio))
                local b = 100

                -- Draw vertex as a small sphere
                core.graphics.circle_3d_filled(pos, 0.3, color.new(r, g, b, 255))

                -- Add vertex index text for debugging (only for close vertices)
                if distance_sq <= 2500 and i % 5 == 0 then -- Only show every 5th vertex to avoid clutter
                    local text_pos = vec3.new(vertex.x, vertex.y, vertex.z + 0.5)
                    core.graphics.text_3d(string.format("V%d", i), text_pos, 12, color.new(255, 255, 255, 255))
                end
            end
        end
    end

    -- Draw walkable polygons if enhanced visualization is enabled
    if self.enhanced_visualization then
        self:draw_walkable_polygons()
    end
end

return TileManager
