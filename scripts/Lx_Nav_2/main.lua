-- Lx_Nav_2 Main Entry Point

-- Core modules
local NavigationManager = require('core/navigation_manager')
local API = require('api/public_api')

-- Initialize global API
_G.Lx_Nav_2 = _G.Lx_Nav_2 or {}

-- Main initialization function
function _G.Lx_Nav_2.init()
    -- Create navigation manager instance
    local nav_manager = NavigationManager:new()
    
    -- Start the navigation manager
    nav_manager:start()

    -- Register render callback to draw paths and debug visuals
    core.register_on_render_callback(function()
        -- Defer to nav_manager.current_path drawing; nav_manager may manage draw timing similar to Lx_Nav
        local PathRenderer = require('rendering/path_renderer')
        if nav_manager and nav_manager.current_path and PathRenderer then
            PathRenderer.draw_path(nav_manager.current_path)
        end
        if nav_manager and nav_manager.alternative_paths and #nav_manager.alternative_paths > 0 and PathRenderer then
            PathRenderer.draw_paths(nav_manager.alternative_paths)
        end
    end)
    
    -- Return public API
    return API.create(nav_manager)
end