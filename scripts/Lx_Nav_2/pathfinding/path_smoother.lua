-- Advanced Path Smoothing and Optimization

local vec3 = require('common/geometry/vector_3')
local Settings = require('config/settings')
local Logger = require('utils/logger')

-- Import algorithm modules
local SplineAlgorithms = require('pathfinding/smoothing/spline_algorithms')
local FilterAlgorithms = require('pathfinding/smoothing/filter_algorithms')

local PathSmoother = {}

-- Available smoothing methods
PathSmoother.METHODS = {
    CHAIKIN = "chaikin",
    BSPLINE = "bspline", 
    CATMULL_ROM = "catmull_rom",
    CENTRIPETAL_CATMULL_ROM = "centripetal_catmull_rom",
    CUBIC_HERMITE = "cubic_hermite",
    BEZIER = "bezier",
    MOVING_AVERAGE = "moving_average",
    GAUSSIAN = "gaussian",
    SAVITZKY_GOLAY = "savitzky_golay",
    LAPLACIAN = "laplacian",
    DOUGLAS_PEUCKER = "douglas_peucker"
}

-- Apply smoothing based on configuration
function PathSmoother.smooth(path, method)
    if not path or #path < 2 then
        return path
    end
    
    if not Settings.get("smoothing.enabled") then
        return path
    end
    
    method = method or Settings.get("smoothing.method") or PathSmoother.METHODS.CHAIKIN
    
    -- Ensure all points are vec3 with numeric coords; skip invalid entries
    local sanitized = {}
    for i = 1, #path do
        local p = path[i]
        if p and type(p.x) == "number" and type(p.y) == "number" and type(p.z) == "number" then
            sanitized[#sanitized + 1] = p
        end
    end
    if #sanitized < 2 then return sanitized end
    local smoothed = sanitized
    
    -- Debug: log smoothing invocation
    if Settings.get('debug.timing') or Settings.get('debug.graph') then
        Logger:debug("PathSmoother.smooth called; method=" .. tostring(method) .. " enabled=" .. tostring(Settings.get('smoothing.enabled')) .. " pts=" .. tostring(#path))
    end

    -- Apply pre-simplification if enabled
    if Settings.get("smoothing.pre_simplify") then
        local tolerance = Settings.get("smoothing.simplify_tolerance") or 3.0
        smoothed = PathSmoother.douglas_peucker(smoothed, tolerance)
    end
    
    -- Apply selected smoothing method
    local iterations = Settings.get("smoothing.iterations") or 3
    
    if method == PathSmoother.METHODS.CHAIKIN then
        smoothed = SplineAlgorithms.chaikin_corner_cutting(smoothed, iterations)
    elseif method == PathSmoother.METHODS.BSPLINE then
        smoothed = SplineAlgorithms.uniform_cubic_bspline(smoothed)
    elseif method == PathSmoother.METHODS.CATMULL_ROM then
        smoothed = SplineAlgorithms.catmull_rom_spline(smoothed)
    elseif method == PathSmoother.METHODS.CENTRIPETAL_CATMULL_ROM then
        smoothed = SplineAlgorithms.centripetal_catmull_rom(smoothed)
    elseif method == PathSmoother.METHODS.CUBIC_HERMITE then
        smoothed = SplineAlgorithms.cubic_hermite_spline(smoothed)
    elseif method == PathSmoother.METHODS.BEZIER then
        smoothed = SplineAlgorithms.bezier_spline(smoothed)
    elseif method == PathSmoother.METHODS.MOVING_AVERAGE then
        smoothed = FilterAlgorithms.moving_average(smoothed, iterations)
    elseif method == PathSmoother.METHODS.GAUSSIAN then
        smoothed = FilterAlgorithms.gaussian_smoothing(smoothed)
    elseif method == PathSmoother.METHODS.SAVITZKY_GOLAY then
        smoothed = FilterAlgorithms.savitzky_golay(smoothed)
    elseif method == PathSmoother.METHODS.LAPLACIAN then
        smoothed = FilterAlgorithms.laplacian_smoothing(smoothed, iterations)
    end
    
    -- Apply post-processing if enabled
    if Settings.get("smoothing.apply_turn_radius") then
        local radius = Settings.get("smoothing.turn_radius") or 2.0
        local segments = Settings.get("smoothing.turn_segments") or 4
        smoothed = PathSmoother.apply_turn_radius(smoothed, radius, segments)
    end
    
    if Settings.get('debug.timing') or Settings.get('debug.graph') then
        Logger:debug("PathSmoother.smooth finished; method=" .. tostring(method) .. " out_pts=" .. tostring(#smoothed))
    end

    return smoothed
end

-- Individual method access (for direct testing)
PathSmoother.chaikin_corner_cutting = SplineAlgorithms.chaikin_corner_cutting
PathSmoother.uniform_cubic_bspline = SplineAlgorithms.uniform_cubic_bspline
PathSmoother.catmull_rom_spline = SplineAlgorithms.catmull_rom_spline
PathSmoother.centripetal_catmull_rom = SplineAlgorithms.centripetal_catmull_rom
PathSmoother.cubic_hermite_spline = SplineAlgorithms.cubic_hermite_spline
PathSmoother.bezier_spline = SplineAlgorithms.bezier_spline
PathSmoother.moving_average = FilterAlgorithms.moving_average
PathSmoother.gaussian_smoothing = FilterAlgorithms.gaussian_smoothing
PathSmoother.savitzky_golay = FilterAlgorithms.savitzky_golay
PathSmoother.laplacian_smoothing = FilterAlgorithms.laplacian_smoothing

-- Douglas-Peucker Simplification
function PathSmoother.douglas_peucker(path, tolerance)
    if #path < 3 then return path end
    
    tolerance = tolerance or 3.0
    
    -- Find point with maximum distance
    local max_dist = 0
    local max_idx = 0
    
    for i = 2, #path - 1 do
        local dist = PathSmoother._perpendicular_distance(path[i], path[1], path[#path])
        if dist > max_dist then
            max_dist = dist
            max_idx = i
        end
    end
    
    -- If max distance is greater than tolerance, recursively simplify
    if max_dist > tolerance then
        local left_path = {}
        for i = 1, max_idx do
            left_path[i] = path[i]
        end
        
        local right_path = {}
        for i = max_idx, #path do
            table.insert(right_path, path[i])
        end
        
        local simplified_left = PathSmoother.douglas_peucker(left_path, tolerance)
        local simplified_right = PathSmoother.douglas_peucker(right_path, tolerance)
        
        -- Combine results
        local result = {}
        for i = 1, #simplified_left - 1 do
            table.insert(result, simplified_left[i])
        end
        for i = 1, #simplified_right do
            table.insert(result, simplified_right[i])
        end
        
        return result
    else
        return {path[1], path[#path]}
    end
end

-- Apply turn radius to path
function PathSmoother.apply_turn_radius(path, radius, segments)
    if #path < 3 then return path end
    
    radius = radius or 2.0
    segments = segments or 4
    
    local result = {path[1]}
    
    for i = 2, #path - 1 do
        local prev = path[i - 1]
        local curr = path[i]
        local next = path[i + 1]
        
        local v1 = (curr - prev):normalize()
        local v2 = (next - curr):normalize()
        local dot = v1:dot(v2)
        local angle = math.acos(math.min(1, math.max(-1, dot)))
        
        if angle > math.pi / 6 then -- 30 degrees
            local arc = PathSmoother._create_arc(prev, curr, next, radius, segments)
            for _, point in ipairs(arc) do
                table.insert(result, point)
            end
        else
            table.insert(result, curr)
        end
    end
    
    table.insert(result, path[#path])
    return result
end

-- Create arc for turn
function PathSmoother._create_arc(p1, p2, p3, radius, segments)
    local v1 = (p2 - p1):normalize()
    local v2 = (p3 - p2):normalize()
    
    local dist1 = p1:distance(p2)
    local dist2 = p2:distance(p3)
    local max_offset = math.min(dist1, dist2) * 0.4
    local offset = math.min(radius, max_offset)
    
    local start_point = p2 - v1 * offset
    local end_point = p2 + v2 * offset
    
    local arc = {}
    for i = 1, segments do
        local t = i / segments
        local point = start_point * (1 - t) * (1 - t) +
                     p2 * 2 * (1 - t) * t +
                     end_point * t * t
        table.insert(arc, point)
    end
    
    return arc
end

-- Helper function: Calculate perpendicular distance
function PathSmoother._perpendicular_distance(point, line_start, line_end)
    local line = line_end - line_start
    local len_sq = line:dot(line)
    
    if len_sq < 0.0001 then
        return point:distance(line_start)
    end
    
    local t = math.max(0, math.min(1, (point - line_start):dot(line) / len_sq))
    local projection = line_start + line * t
    
    return point:distance(projection)
end

-- Straighten path using visibility checks
function PathSmoother.straighten_with_visibility(path, visibility_check_fn)
    if #path < 3 or not visibility_check_fn then
        return path
    end
    
    local result = {path[1]}
    local current_idx = 1
    
    while current_idx < #path do
        local farthest = current_idx + 1
        
        -- Find farthest visible point
        for i = current_idx + 2, #path do
            if visibility_check_fn(path[current_idx], path[i]) then
                farthest = i
            else
                break
            end
        end
        
        table.insert(result, path[farthest])
        current_idx = farthest
    end
    
    return result
end

-- Add humanization to path
function PathSmoother.humanize(path)
    if not Settings.get("movement.humanize") then
        return path
    end
    
    local factor = Settings.get("movement.humanize_factor") or 0.15
    local result = {path[1]} -- Keep start point exact
    
    for i = 2, #path - 1 do
        local point = path[i]
        -- Add small random offset
        local offset = vec3:new(
            (math.random() - 0.5) * factor,
            (math.random() - 0.5) * factor,
            0 -- Don't change Z
        )
        table.insert(result, point + offset)
    end
    
    table.insert(result, path[#path]) -- Keep end point exact
    return result
end

return PathSmoother