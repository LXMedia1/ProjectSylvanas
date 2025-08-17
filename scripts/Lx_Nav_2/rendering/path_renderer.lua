-- Path Rendering Module

local vec3 = require('common/geometry/vector_3')
local color = require('common/color')
local Settings = require('config/settings')

local PathRenderer = {}
local _renderer_cap_checked = false
local function _check_renderer_capabilities()
    if _renderer_cap_checked then return end
    _renderer_cap_checked = true
    local has_any = false
    if core.graphics then
        if core.graphics.line_3d then has_any = true end
        if core.graphics.circle_3d_filled then has_any = true end
        if core.graphics.circle_3d then has_any = true end
        if core.graphics.text_3d then has_any = true end
        if core.graphics.triangle_3d_filled then has_any = true end
    end
    if not has_any then
        core.log_warning("[Lx_Nav_2] core.graphics missing draw functions (line_3d/circle_3d_filled/text_3d/triangle_3d_filled) - nothing will render")
    end
end

-- Draw a path
function PathRenderer.draw_path(path, path_color, thickness)
    if not path or #path < 2 then return end
    if not Settings.get("debug.draw_path") then return end
    _check_renderer_capabilities()
    
    -- Default color and thickness
    path_color = path_color or Settings.get("rendering.path_color") or {0, 1, 0, 0.8}
    thickness = thickness or 2.0
    
    local c = color.new(path_color[1], path_color[2], path_color[3], path_color[4])
    
    -- Draw path segments
    for i = 1, #path - 1 do
        local start_pos = path[i]
        local end_pos = path[i + 1]
        
        if core.graphics and core.graphics.line_3d then
            core.graphics.line_3d(start_pos, end_pos, c, thickness)
        end
        
        -- Draw node markers
        if i == 1 then
            -- Start marker (green sphere)
            PathRenderer.draw_node(start_pos, color.new(0, 1, 0, 1), 0.3)
        end
    end
    
    -- End marker (red sphere)
    if #path > 0 then
        PathRenderer.draw_node(path[#path], color.new(1, 0, 0, 1), 0.3)
    end
end

-- Draw multiple paths
function PathRenderer.draw_paths(paths)
    if not paths or #paths == 0 then return end
    
    local main_color = Settings.get("rendering.path_color") or {0, 1, 0, 0.8}
    local alt_color = Settings.get("rendering.alt_path_color") or {1, 1, 0, 0.5}
    
    for i, path in ipairs(paths) do
        local path_color = (i == 1) and main_color or alt_color
        PathRenderer.draw_path(path, path_color, (i == 1) and 2.0 or 1.5)
    end
end

-- Draw a node/waypoint
function PathRenderer.draw_node(position, node_color, radius)
    if not position then return end
    
    radius = radius or 0.2
    node_color = node_color or color.new(1, 1, 1, 1)
    
    if core.graphics and core.graphics.circle_3d_filled then
        core.graphics.circle_3d_filled(position, radius, node_color)
    elseif core.graphics and core.graphics.circle_3d then
        core.graphics.circle_3d(position, radius, node_color, 1.0)
    end
end

-- Draw path with distance text
function PathRenderer.draw_path_with_distances(path)
    if not path or #path < 2 then return end
    
    PathRenderer.draw_path(path)
    
    -- Calculate and display distances
    local total_distance = 0
    for i = 1, #path - 1 do
        local dist = path[i]:distance(path[i + 1])
        total_distance = total_distance + dist
        
        -- Draw distance text at midpoint
        if core.graphics and core.graphics.text_3d then
            local midpoint = (path[i] + path[i + 1]) / 2
            local text = string.format("%.1fm", dist)
            core.graphics.text_3d(text, midpoint, 12, color.new(1, 1, 1, 1), false, 0)
        end
    end
    
    -- Draw total distance
    if core.graphics and core.graphics.text_3d and #path > 0 then
        local text = string.format("Total: %.1fm", total_distance)
        core.graphics.text_3d(text, path[#path], 12, color.new(1, 0.5, 0, 1), false, 0)
    end
end

-- Draw corridor (series of connected polygons)
function PathRenderer.draw_corridor(polygon_ids, all_polygons)
    if not Settings.get("debug.draw_corridor_layers") then return end
    if not polygon_ids or not all_polygons then return end
    
    for i, poly_id in ipairs(polygon_ids) do
        local poly = all_polygons[poly_id]
        if poly then
            -- Color based on position in corridor
            local t = (i - 1) / math.max(1, #polygon_ids - 1)
            local r = 1 - t
            local g = t
            local corridor_color = color.new(r, g, 0.5, 0.3)
            
            -- Draw polygon
            if poly.vertices and #poly.vertices >= 3 then
                PathRenderer.draw_polygon(poly.vertices, corridor_color)
            end
        end
    end
end

-- Draw a polygon
function PathRenderer.draw_polygon(vertices, poly_color, filled)
    if not vertices or #vertices < 3 then return end
    
    poly_color = poly_color or color.new(0.5, 0.5, 1, 0.3)
    filled = filled ~= false -- Default to filled
    
    if filled and core.graphics and core.graphics.triangle_3d_filled then
        -- Draw as triangle fan
        for i = 2, #vertices - 1 do
            core.graphics.triangle_3d_filled(vertices[1], vertices[i], vertices[i + 1], poly_color)
        end
    else
        -- Draw edges with 3D line
        for i = 1, #vertices do
            local v1 = vertices[i]
            local v2 = vertices[(i % #vertices) + 1]
            if core.graphics and core.graphics.line_3d then
                core.graphics.line_3d(v1, v2, poly_color, 1.0)
            end
        end
    end
end

return PathRenderer