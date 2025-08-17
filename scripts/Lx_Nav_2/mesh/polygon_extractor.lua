-- Polygon Extraction and Processing

local vec3 = require('common/geometry/vector_3')
local Logger = require('utils/logger')

local PolygonExtractor = {}

-- Extract walkable polygons from tile data
function PolygonExtractor.extract_polygons(tile_data)
    if not tile_data or not tile_data.polygons or not tile_data.vertices then
        return {}
    end
    
    local polygons = {}
    local vertices = tile_data.vertices
    local header = tile_data.header
    
    if require('config/settings').get('debug.extraction') then
        Logger:debug("Extractor: polys=" .. tostring(header and header.polyCount or -1) ..
                     " verts=" .. tostring(header and header.vertCount or -1))
    end

    for poly_idx, poly in ipairs(tile_data.polygons) do
        if PolygonExtractor._is_walkable(poly) then
            local extracted = PolygonExtractor._extract_single_polygon(
                poly, poly_idx, vertices, header
            )
            if extracted then
                if require('config/settings').get('debug.extraction') then
                    Logger:debug("Extractor: polyIndex=" .. tostring(poly_idx) ..
                                 " vertCount=" .. tostring(poly.vertCount) ..
                                 " areaType=" .. tostring(poly.areaAndtype))
                end
                table.insert(polygons, extracted)
            end
        end
    end
    
    return polygons
end

-- Check if polygon is walkable
function PolygonExtractor._is_walkable(poly)
    if not poly then return false end
    
    -- Basic validity: require a reasonable vertex count
    if not poly.vertCount or poly.vertCount < 3 or poly.vertCount > 6 then
        return false
    end

    -- Accept ground polygons (type 0) as in Lx_Nav
    local area_and_type = poly.areaAndtype or 0
    local poly_type = math.floor(area_and_type / 64) % 4
    return poly_type == 0
end

-- Extract single polygon data
function PolygonExtractor._extract_single_polygon(poly, index, vertices, header)
    local verts = {}
    local min_z = math.huge
    local max_z = -math.huge
    
    -- Extract vertex positions
    for i = 1, poly.vertCount do
        local vert_idx = poly.verts[i]
        if vert_idx == 0xFFFF then
            break
        end
        
        -- Lx_Nav uses flattened vertex array; convert index accordingly
        local base_index = vert_idx * 3 + 1
        local vx_f = vertices[base_index]
        local vy_f = vertices[base_index + 1]
        local vz_f = vertices[base_index + 2]
        if not vx_f or not vy_f or not vz_f then
            Logger:warning("Invalid vertex index: " .. vert_idx)
            return nil
        end
        local pos = vec3.new(vx_f, vy_f, vz_f)
        table.insert(verts, pos)
        
        min_z = math.min(min_z, vz_f)
        max_z = math.max(max_z, vz_f)
    end
    
    if #verts < 3 then
        return nil
    end
    
    -- Calculate polygon center
    local center = vec3.new(0, 0, 0)
    for _, v in ipairs(verts) do
        if v and v.x and v.y and v.z then
            center = center + v
        end
    end
    center = center / #verts
    
    -- Calculate area
    local area = PolygonExtractor._calculate_area(verts)
    if area <= 0.0001 then
        return nil
    end
    
    -- Extract neighbor information
    local neighbors = {}
    for i = 1, poly.vertCount do
        local nei = poly.neis[i]
        if nei and nei ~= 0 and nei ~= 0xFFFF then
            -- External link flag is 0x8000
            local is_external = (nei >= 0x8000)
            local link_idx = nei % 0x8000
            
            table.insert(neighbors, {
                edge = i,
                is_external = is_external,
                link = link_idx
            })
        end
    end
    
    return {
        index = index,
        vertices = verts,
        center = center,
        min_z = min_z,
        max_z = max_z,
        area = area,
        neighbors = neighbors,
        flags = poly.flags,
        area_type = poly.areaAndtype,
        vertex_count = #verts
    }
end

-- Calculate polygon area using shoelace formula
function PolygonExtractor._calculate_area(vertices)
    if #vertices < 3 then return 0 end
    
    local area = 0
    for i = 1, #vertices do
        local j = (i % #vertices) + 1
        local v1 = vertices[i]
        local v2 = vertices[j]
        area = area + (v1.x * v2.y - v2.x * v1.y)
    end
    
    return math.abs(area / 2)
end

-- Merge polygons from multiple tiles
function PolygonExtractor.merge_polygons(tile_polygons)
    local merged = {}
    local polygon_id = 1
    
    for tile_key, polygons in pairs(tile_polygons) do
        for _, poly in ipairs(polygons) do
            -- Create new polygon with global ID
            local merged_poly = {}
            for k, v in pairs(poly) do
                merged_poly[k] = v
            end
            merged_poly.global_id = polygon_id
            merged_poly.tile_key = tile_key
            
            merged[polygon_id] = merged_poly
            polygon_id = polygon_id + 1
        end
    end
    
    local tiles_count = 0
    for _ in pairs(tile_polygons) do tiles_count = tiles_count + 1 end
    if require('config/settings').get('debug.merge') then
        Logger:debug("Merge: inputTiles=" .. tostring(tiles_count) ..
                     " mergedPolys=" .. tostring(polygon_id - 1))
    end
    
    return merged
end

-- Find polygon containing a point
function PolygonExtractor.find_containing_polygon(point, polygons)
    local best_poly = nil
    local best_dist = math.huge
    
    for _, poly in pairs(polygons) do
        if PolygonExtractor._point_in_polygon(point, poly.vertices) then
            -- Check vertical distance
            if point.z >= poly.min_z - 2 and point.z <= poly.max_z + 2 then
                local dist = math.abs(point.z - poly.center.z)
                if dist < best_dist then
                    best_dist = dist
                    best_poly = poly
                end
            end
        end
    end
    
    return best_poly
end

-- Check if point is inside polygon (2D)
function PolygonExtractor._point_in_polygon(point, vertices)
    local inside = false
    local n = #vertices
    
    local p1 = vertices[n]
    for i = 1, n do
        local p2 = vertices[i]
        
        if ((p2.y > point.y) ~= (p1.y > point.y)) and
           (point.x < (p1.x - p2.x) * (point.y - p2.y) / (p1.y - p2.y) + p2.x) then
            inside = not inside
        end
        
        p1 = p2
    end
    
    return inside
end

return PolygonExtractor