-- Navigation Mesh Rendering Module

local vec3 = require('common/geometry/vector_3')
local color = require('common/color')
local Settings = require('config/settings')
local Profiler = require('utils/profiler')

local MeshRenderer = {}

-- Draw all navigation polygons
function MeshRenderer.draw_polygons(polygons, budget_ms)
    if not Settings.get("debug.draw_navmesh") then return end
    if not polygons then return end
    
    budget_ms = budget_ms or Settings.get("rendering.navmesh_budget_ms") or 1.5
    local budget = Profiler.BudgetTracker:new(budget_ms)
    budget:start()
    
    local poly_color = Settings.get("rendering.polygon_color") or {0.5, 0.5, 1, 0.3}
    local c = color.new(poly_color[1], poly_color[2], poly_color[3], poly_color[4])
    
    local drawn = 0
    for _, poly in pairs(polygons) do
        if not budget:has_budget() then
            break
        end
        
        if poly.vertices and #poly.vertices >= 3 then
            MeshRenderer.draw_single_polygon(poly, c)
            drawn = drawn + 1
        end
    end
    
    return drawn
end

-- Draw a single polygon
function MeshRenderer.draw_single_polygon(polygon, poly_color)
    if not polygon or not polygon.vertices then return end
    
    poly_color = poly_color or color.new(0.5, 0.5, 1, 0.3)
    
    -- Draw filled polygon
    if core.graphics and core.graphics.triangle_3d_filled then
        -- draw as triangle fan
        for i = 2, #polygon.vertices - 1 do
            core.graphics.triangle_3d_filled(polygon.vertices[1], polygon.vertices[i], polygon.vertices[i + 1], poly_color)
        end
    end
    
    -- Draw edges with darker color
    local edge_color = color.new(
        poly_color.r * 0.7,
        poly_color.g * 0.7,
        poly_color.b * 0.7,
        math.min(1, poly_color.a * 2)
    )
    
    for i = 1, #polygon.vertices do
        local v1 = polygon.vertices[i]
        local v2 = polygon.vertices[(i % #polygon.vertices) + 1]
        
        if core.graphics and core.graphics.line_3d then
            core.graphics.line_3d(v1, v2, edge_color, 1.0)
        end
    end
    
    -- Draw center point if debug enabled
    if Settings.get("debug.enhanced_visualization") then
        MeshRenderer.draw_polygon_center(polygon)
    end
end

-- Draw polygon center
function MeshRenderer.draw_polygon_center(polygon)
    if not polygon or not polygon.center then return end
    
    local center_color = color.new(1, 1, 0, 0.8)
    
    if core.graphics and core.graphics.circle_3d_filled then
        core.graphics.circle_3d_filled(polygon.center, 0.1, center_color)
    end
    
    -- Draw polygon ID if available
    if polygon.global_id and core.graphics and core.graphics.text_3d then
        local text = tostring(polygon.global_id)
        core.graphics.text_3d(text, polygon.center, 12, color.new(1, 1, 1, 1), false, 0)
    end
end

-- Draw polygon connections
function MeshRenderer.draw_connections(polygons, graph)
    if not Settings.get("debug.enhanced_visualization") then return end
    if not polygons or not graph then return end
    
    local conn_color = color.new(0, 1, 1, 0.5)
    
    for poly_id, poly in pairs(polygons) do
        local edges = graph:get_edges(poly_id)
        if edges then
            for _, edge in ipairs(edges) do
                local target_poly = polygons[edge.to]
                if target_poly and poly.center and target_poly.center then
                    if core.graphics and core.graphics.line_3d then
                        core.graphics.line_3d(
                            poly.center,
                            target_poly.center,
                            conn_color,
                            0.5
                        )
                    end
                end
            end
        end
    end
end

-- Draw tile boundaries
function MeshRenderer.draw_tile_boundaries(loaded_tiles)
    if not loaded_tiles then return end
    
    local boundary_color = color.new(1, 0, 1, 0.5)
    local TILE_SIZE = 533.33333
    
    for tile_key, _ in pairs(loaded_tiles) do
        local x, y = tile_key:match("(-?%d+):(-?%d+)")
        if x and y then
            x, y = tonumber(x), tonumber(y)
            
            local min_x = x * TILE_SIZE
            local max_x = (x + 1) * TILE_SIZE
            local min_y = y * TILE_SIZE
            local max_y = (y + 1) * TILE_SIZE
            
            -- Get current Z position for drawing
            local player = core.object_manager and core.object_manager.get_local_player()
            local z = player and player:get_position().z or 0
            
            -- Draw tile boundary
            local corners = {
                vec3.new(min_x, min_y, z),
                vec3.new(max_x, min_y, z),
                vec3.new(max_x, max_y, z),
                vec3.new(min_x, max_y, z)
            }
            
            for i = 1, 4 do
                local v1 = corners[i]
                local v2 = corners[(i % 4) + 1]
                if core.graphics and core.graphics.line_3d then
                    core.graphics.line_3d(v1, v2, boundary_color, 2.0)
                end
            end
            
            -- Draw tile coordinates
            if core.graphics and core.graphics.text_3d then
                local center = vec3.new((min_x + max_x) / 2, (min_y + max_y) / 2, z)
                local text = string.format("Tile %d,%d", x, y)
                core.graphics.text_3d(text, center, 12, color.new(1, 1, 1, 1), false, 0)
            end
        end
    end
end

-- Draw debug grid
function MeshRenderer.draw_grid(center, size, spacing)
    if not Settings.get("debug.enhanced_visualization") then return end
    
    center = center or vec3:new(0, 0, 0)
    size = size or 100
    spacing = spacing or 10
    
    local grid_color = color.new(0.3, 0.3, 0.3, 0.5)
    local axis_color = color.new(0.7, 0.7, 0.7, 0.8)
    
    local half_size = size / 2
    local num_lines = math.floor(size / spacing) + 1
    
    for i = 0, num_lines do
        local offset = -half_size + (i * spacing)
        
        -- Choose color (highlight axes)
        local line_color = (math.abs(offset) < 0.1) and axis_color or grid_color
        
        -- X-axis lines
        local x_start = vec3.new(center.x - half_size, center.y + offset, center.z)
        local x_end = vec3.new(center.x + half_size, center.y + offset, center.z)
        
        -- Y-axis lines
        local y_start = vec3.new(center.x + offset, center.y - half_size, center.z)
        local y_end = vec3.new(center.x + offset, center.y + half_size, center.z)
        
        if core.graphics and core.graphics.line_3d then
            core.graphics.line_3d(x_start, x_end, line_color, 0.5)
            core.graphics.line_3d(y_start, y_end, line_color, 0.5)
        end
    end
end

return MeshRenderer