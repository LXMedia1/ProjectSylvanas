-- Public API for Lx_Nav_2

local Settings = require('config/settings')
local Logger = require('utils/logger')

local API = {}

-- Create public API instance
function API.create(nav_manager)
    local api = {
        -- Internal reference
        __nav = nav_manager
    }
    
    -- === SETTINGS API ===
    
    -- Enable/disable debug mode
    function api.set_debug(enabled)
        Settings.set("debug.enabled", enabled)
        Settings.set("debug.log_enabled", enabled)
        Logger:set_enabled(enabled)
    end
    
    -- Enable/disable path drawing
    function api.set_show_path(enabled)
        Settings.set("debug.draw_path", enabled)
    end
    
    -- Enable/disable debug logging
    function api.set_debuglog(enabled)
        Settings.set("debug.log_enabled", enabled)
        Logger:set_enabled(enabled)
    end

    -- Fine-grained debug categories
    function api.set_debug_extraction(enabled)
        Settings.set("debug.extraction", enabled)
    end
    function api.set_debug_merge(enabled)
        Settings.set("debug.merge", enabled)
    end
    function api.set_debug_graph(enabled)
        Settings.set("debug.graph", enabled)
    end
    function api.set_debug_tiles(enabled)
        Settings.set("debug.tiles", enabled)
    end
    function api.set_debug_eviction(enabled)
        Settings.set("debug.eviction", enabled)
    end
    function api.set_debug_timing(enabled)
        Settings.set("debug.timing", enabled)
    end

    -- Extraction budget
    function api.set_extract_budget_ms(ms)
        if ms and ms >= 0 then
            Settings.set("tiles.extract_budget_ms", ms)
        end
    end
    
    -- Enable/disable looking at movement direction
    function api.set_use_look_at(enabled)
        Settings.set("movement.use_look_at", enabled)
    end
    
    -- Enable/disable corridor layer drawing
    function api.set_draw_corridor_layers(enabled)
        Settings.set("debug.draw_corridor_layers", enabled)
    end
    
    -- Enable/disable polygon drawing
    function api.set_draw_path_polys(enabled)
        Settings.set("debug.draw_polygons", enabled)
    end
    
    -- === MOVEMENT API ===
    
    -- Move to a position
    function api.move_to(position, direct, on_finish)
        if direct then
            -- Direct movement without pathfinding
            local simple_path = {
                nav_manager.current_position or core.object_manager.get_local_player():get_position(),
                position
            }
            nav_manager.movement_controller:start_path(simple_path, on_finish)
        else
            -- Pathfinding movement
            nav_manager:move_to(position, on_finish)
        end
    end
    
    -- Stop all movement
    function api.stop()
        nav_manager:stop_movement()
    end
    
    -- === PATH QUERIES API ===
    
    -- Get path between two points or get current path
    function api.get_path(start_pos, end_pos)
        if start_pos and end_pos then
            -- Find path between two points
            local saved_pos = nav_manager.current_position
            nav_manager.current_position = start_pos
            
            local path = nav_manager:find_path(end_pos)
            
            -- If a path was found, cache it for rendering like the original Lx_Nav
            if path and #path >= 2 then
                nav_manager.current_path = path
                nav_manager._path_draw_until_ms = (core.time() or 0) + 300000 -- 5 minutes
            end

            nav_manager.current_position = saved_pos
            return path
        else
            -- Return current path
            return nav_manager:get_current_path()
        end
    end
    
    -- Find alternative paths
    function api.find_alternative_paths(destination, count)
        return nav_manager:find_alternative_paths(destination, count)
    end
    
    -- === STATUS API ===
    
    -- Check if currently moving
    function api.is_moving()
        return nav_manager:is_moving()
    end
    
    -- Get movement progress (0-1)
    function api.get_progress()
        return nav_manager:get_movement_progress()
    end
    
    -- === ADVANCED API ===
    
    -- Clear all navigation data
    function api.clear()
        nav_manager:clear_navigation_data()
    end
    
    -- Rebuild navigation graph
    function api.rebuild_graph()
        nav_manager:rebuild_graph()
    end

    -- Ensure nearby tiles are queued and loaded, then rebuild graph (helper for examples)
    function api.ensure_tiles_and_build(radius)
        local Settings = require('config/settings')
        local player = core.object_manager and core.object_manager.get_local_player()
        if not player then return 0 end
        local pos = player:get_position()
        if not pos then return 0 end
        -- Use the same 64x64 world->tile conversion used by the loader
        local Coordinates = require('utils/coordinates')
        local tile_x, tile_y = Coordinates.world_to_tile(pos.x, pos.y)
        local instance_id = (core and core.get_instance_id) and core.get_instance_id() or 0
        local r = radius or Settings.get("tiles.load_radius") or 2
        local queued = nav_manager.tile_manager:queue_tiles_around(instance_id, tile_x, tile_y, r)
        local budget_ms = (Settings.get("tiles.load_budget_ms") or 2.0) * 50
        local loaded = nav_manager.tile_manager:process_load_queue(budget_ms)
        nav_manager.needs_graph_rebuild = true
        nav_manager:rebuild_graph()
        return loaded or 0
    end
    
    -- Get loaded tile count
    function api.get_tile_count()
        local tiles = nav_manager.tile_manager:get_loaded_tiles()
        return #tiles
    end
    
    -- Get polygon count
    function api.get_polygon_count()
        local count = 0
        for _ in pairs(nav_manager.all_polygons) do
            count = count + 1
        end
        return count
    end
    
    -- Get graph build progress
    function api.get_graph_progress()
        return nav_manager.graph_builder:get_progress()
    end

    -- Check if graph is ready for path queries
    function api.is_graph_ready()
        local building = nav_manager.graph_builder.is_building
        local progress = nav_manager.graph_builder:get_progress() or 0
        if building then return false end
        return progress >= 1.0
    end
    
    -- === CONFIGURATION API ===
    
    -- Set tile load radius
    function api.set_tile_radius(load_radius, keep_radius)
        if load_radius then
            Settings.set("tiles.load_radius", load_radius)
        end
        if keep_radius then
            Settings.set("tiles.keep_radius", keep_radius)
        end
    end
    
    -- Set pathfinding weights
    function api.set_path_weights(clearance_weight, layer_weight)
        if clearance_weight then
            Settings.set("pathfinding.weight_clearance", clearance_weight)
        end
        if layer_weight then
            Settings.set("pathfinding.weight_layer", layer_weight)
        end
    end
    
    -- Set smoothing options
    function api.set_smoothing(enabled, method, iterations, tolerance)
        if enabled ~= nil then
            Settings.set("smoothing.enabled", enabled)
        end
        if method then
            Settings.set("smoothing.method", method)
        end
        if iterations then
            Settings.set("smoothing.iterations", iterations)
        end
        if tolerance then
            Settings.set("smoothing.simplify_tolerance", tolerance)
        end
    end
    
    -- Set specific smoothing method
    function api.set_smoothing_method(method)
        local PathSmoother = require('pathfinding/path_smoother')
        if PathSmoother.METHODS[string.upper(method)] then
            Settings.set("smoothing.method", method)
            return true
        end
        return false
    end
    
    -- Get available smoothing methods
    function api.get_smoothing_methods()
        local PathSmoother = require('pathfinding/path_smoother')
        return PathSmoother.METHODS
    end
    
    -- Set method-specific parameters
    function api.set_smoothing_params(params)
        for key, value in pairs(params) do
            Settings.set("smoothing." .. key, value)
        end
    end

    -- Get current smoothing method
    function api.get_smoothing_method()
        return Settings.get("smoothing.method")
    end
    
    -- Set movement options
    function api.set_movement_options(arrive_distance, stuck_threshold, humanize)
        if arrive_distance then
            Settings.set("movement.arrive_distance", arrive_distance)
        end
        if stuck_threshold then
            Settings.set("movement.stuck_threshold", stuck_threshold)
        end
        if humanize ~= nil then
            Settings.set("movement.humanize", humanize)
        end
    end
    
    -- === RENDERING API (if available) ===
    
    -- Draw current path
    function api.draw_path(path)
        -- Draw a provided path, or fallback to current_path
        local Renderer = require('rendering/path_renderer')
        -- Diagnostic log to help debug missing rendering
        local graphics_present = (core and core.graphics) and true or false
        core.log("[Lx_Nav_2][API] draw_path called; debug.draw_path=" .. tostring(Settings.get("debug.draw_path")) .. ", graphics_present=" .. tostring(graphics_present))
        if graphics_present then
            core.log("[Lx_Nav_2][API] graphics.line_3d=" .. tostring(core.graphics.line_3d ~= nil) .. ", circle_3d_filled=" .. tostring(core.graphics.circle_3d_filled ~= nil) .. ", circle_3d=" .. tostring(core.graphics.circle_3d ~= nil) .. ", text_3d=" .. tostring(core.graphics.text_3d ~= nil) .. ", triangle_3d_filled=" .. tostring(core.graphics.triangle_3d_filled ~= nil))
        end
        if not Renderer then return end
        if path and #path > 1 then
            Renderer.draw_path(path)
            return
        end
        if nav_manager.current_path then
            Renderer.draw_path(nav_manager.current_path)
        end
    end
    
    -- Draw navigation mesh
    function api.draw_navmesh()
        -- This would be implemented in rendering module
        local Renderer = require('rendering/mesh_renderer')
        if Renderer then
            Renderer.draw_polygons(nav_manager.all_polygons)
        end
    end
    
    return api
end

return API