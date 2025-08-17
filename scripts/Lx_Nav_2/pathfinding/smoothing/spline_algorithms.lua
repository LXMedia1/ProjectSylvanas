-- Spline-based Smoothing Algorithms

local vec3 = require('common/geometry/vector_3')
local Settings = require('config/settings')

local SplineAlgorithms = {}

-- 1. Chaikin's Corner Cutting (Classic)
function SplineAlgorithms.chaikin_corner_cutting(path, iterations)
    if #path < 3 then return path end
    
    iterations = iterations or 3
    local smoothed = path
    
    for iter = 1, iterations do
        local new_path = {smoothed[1]} -- Keep first point
        
        for i = 1, #smoothed - 1 do
            local p1 = smoothed[i]
            local p2 = smoothed[i + 1]
            
            -- Create two new points using 1:3 and 3:1 ratios
            local q = p1 * 0.75 + p2 * 0.25
            local r = p1 * 0.25 + p2 * 0.75
            
            table.insert(new_path, q)
            if i < #smoothed - 1 then
                table.insert(new_path, r)
            end
        end
        
        table.insert(new_path, smoothed[#smoothed]) -- Keep last point
        smoothed = new_path
    end
    
    return smoothed
end

-- 2. Uniform Cubic B-Splines
function SplineAlgorithms.uniform_cubic_bspline(path, resolution)
    if #path < 4 then return path end
    
    resolution = resolution or Settings.get("smoothing.bspline_resolution") or 0.1
    local result = {}
    
    -- Add duplicate endpoints for proper interpolation
    local control_points = {path[1], path[1]}
    for i = 1, #path do
        table.insert(control_points, path[i])
    end
    table.insert(control_points, path[#path])
    table.insert(control_points, path[#path])
    
    -- Generate curve points
    for i = 3, #control_points - 2 do
        local p0 = control_points[i - 1]
        local p1 = control_points[i]
        local p2 = control_points[i + 1]
        local p3 = control_points[i + 2]
        
        local t = 0
        while t <= 1 do
            local point = SplineAlgorithms._cubic_bspline_point(p0, p1, p2, p3, t)
            table.insert(result, point)
            t = t + resolution
        end
    end
    
    return result
end

-- 3. Catmull-Rom Splines
function SplineAlgorithms.catmull_rom_spline(path, tension, resolution)
    if #path < 3 then return path end
    
    tension = tension or Settings.get("smoothing.catmull_rom_tension") or 0.5
    resolution = resolution or Settings.get("smoothing.catmull_rom_resolution") or 0.1
    
    local result = {path[1]}
    
    for i = 2, #path - 1 do
        local p0 = path[math.max(1, i - 1)]
        local p1 = path[i]
        local p2 = path[i + 1]
        local p3 = path[math.min(#path, i + 2)]
        
        local t = 0
        while t <= 1 do
            local point = SplineAlgorithms._catmull_rom_point(p0, p1, p2, p3, t, tension)
            table.insert(result, point)
            t = t + resolution
        end
    end
    
    table.insert(result, path[#path])
    return result
end

-- 4. Centripetal Catmull-Rom
function SplineAlgorithms.centripetal_catmull_rom(path, alpha, resolution)
    if #path < 3 then return path end
    
    alpha = alpha or Settings.get("smoothing.centripetal_alpha") or 0.5
    resolution = resolution or Settings.get("smoothing.centripetal_resolution") or 0.1
    
    local result = {path[1]}
    
    for i = 2, #path - 1 do
        local p0 = path[math.max(1, i - 1)]
        local p1 = path[i]
        local p2 = path[i + 1]
        local p3 = path[math.min(#path, i + 2)]
        
        -- Calculate knots using centripetal parameterization
        local t0 = 0
        local t1 = SplineAlgorithms._get_t(t0, p0, p1, alpha)
        local t2 = SplineAlgorithms._get_t(t1, p1, p2, alpha)
        local t3 = SplineAlgorithms._get_t(t2, p2, p3, alpha)
        
        local t = t1
        while t <= t2 do
            local point = SplineAlgorithms._centripetal_catmull_rom_point(p0, p1, p2, p3, t0, t1, t2, t3, t)
            table.insert(result, point)
            t = t + resolution * (t2 - t1)
        end
    end
    
    table.insert(result, path[#path])
    return result
end

-- 5. Cubic Hermite Splines (PCHIP)
function SplineAlgorithms.cubic_hermite_spline(path, resolution)
    if #path < 3 then return path end
    
    resolution = resolution or Settings.get("smoothing.hermite_resolution") or 0.1
    
    -- Calculate tangents using finite differences (monotonicity preserving)
    local tangents = SplineAlgorithms._calculate_pchip_tangents(path)
    local result = {path[1]}
    
    for i = 1, #path - 1 do
        local p1 = path[i]
        local p2 = path[i + 1]
        local t1 = tangents[i]
        local t2 = tangents[i + 1]
        
        local t = 0
        while t <= 1 do
            local point = SplineAlgorithms._cubic_hermite_point(p1, p2, t1, t2, t)
            table.insert(result, point)
            t = t + resolution
        end
    end
    
    return result
end

-- 6. Bezier Splines
function SplineAlgorithms.bezier_spline(path, control_factor)
    if #path < 3 then return path end
    
    control_factor = control_factor or Settings.get("smoothing.bezier_control_factor") or 0.3
    local result = {path[1]}
    
    for i = 1, #path - 1 do
        local p1 = path[i]
        local p2 = path[i + 1]
        
        -- Calculate control points
        local c1, c2 = SplineAlgorithms._calculate_bezier_controls(path, i, control_factor)
        
        local t = 0
        while t <= 1 do
            local point = SplineAlgorithms._cubic_bezier_point(p1, c1, c2, p2, t)
            table.insert(result, point)
            t = t + 0.1
        end
    end
    
    return result
end

-- Helper functions for spline calculations

-- Cubic B-spline point calculation
function SplineAlgorithms._cubic_bspline_point(p0, p1, p2, p3, t)
    local t2 = t * t
    local t3 = t2 * t
    
    local w0 = (-t3 + 3*t2 - 3*t + 1) / 6
    local w1 = (3*t3 - 6*t2 + 4) / 6
    local w2 = (-3*t3 + 3*t2 + 3*t + 1) / 6
    local w3 = t3 / 6
    
    return p0 * w0 + p1 * w1 + p2 * w2 + p3 * w3
end

-- Catmull-Rom point calculation
function SplineAlgorithms._catmull_rom_point(p0, p1, p2, p3, t, tension)
    local t2 = t * t
    local t3 = t2 * t
    
    local v0 = (p2 - p0) * tension
    local v1 = (p3 - p1) * tension
    
    return p1 * (2*t3 - 3*t2 + 1) + 
           p2 * (-2*t3 + 3*t2) + 
           v0 * (t3 - 2*t2 + t) + 
           v1 * (t3 - t2)
end

-- Get t value for centripetal parameterization
function SplineAlgorithms._get_t(ti, pi, pj, alpha)
    local xi = pi.x - pj.x
    local yi = pi.y - pj.y
    local zi = pi.z - pj.z
    local dist = math.sqrt(xi*xi + yi*yi + zi*zi)
    return ti + (dist ^ alpha)
end

-- Centripetal Catmull-Rom point
function SplineAlgorithms._centripetal_catmull_rom_point(p0, p1, p2, p3, t0, t1, t2, t3, t)
    local a1 = p0 * ((t1 - t) / (t1 - t0)) + p1 * ((t - t0) / (t1 - t0))
    local a2 = p1 * ((t2 - t) / (t2 - t1)) + p2 * ((t - t1) / (t2 - t1))
    local a3 = p2 * ((t3 - t) / (t3 - t2)) + p3 * ((t - t2) / (t3 - t2))
    
    local b1 = a1 * ((t2 - t) / (t2 - t0)) + a2 * ((t - t0) / (t2 - t0))
    local b2 = a2 * ((t3 - t) / (t3 - t1)) + a3 * ((t - t1) / (t3 - t1))
    
    return b1 * ((t2 - t) / (t2 - t1)) + b2 * ((t - t1) / (t2 - t1))
end

-- Calculate PCHIP tangents
function SplineAlgorithms._calculate_pchip_tangents(path)
    local tangents = {}
    
    for i = 1, #path do
        if i == 1 then
            tangents[i] = path[2] - path[1]
        elseif i == #path then
            tangents[i] = path[#path] - path[#path - 1]
        else
            local d1 = path[i] - path[i - 1]
            local d2 = path[i + 1] - path[i]
            
            -- Use harmonic mean for monotonicity preservation
            if d1:dot(d2) <= 0 then
                tangents[i] = vec3:new(0, 0, 0)
            else
                tangents[i] = (d1 + d2) / 2
            end
        end
    end
    
    return tangents
end

-- Cubic Hermite point
function SplineAlgorithms._cubic_hermite_point(p1, p2, t1, t2, t)
    local t2 = t * t
    local t3 = t2 * t
    
    local h00 = 2*t3 - 3*t2 + 1
    local h10 = t3 - 2*t2 + t
    local h01 = -2*t3 + 3*t2
    local h11 = t3 - t2
    
    return p1 * h00 + t1 * h10 + p2 * h01 + t2 * h11
end

-- Calculate Bezier control points
function SplineAlgorithms._calculate_bezier_controls(path, i, factor)
    local p1 = path[i]
    local p2 = path[i + 1]
    
    local prev = i > 1 and path[i - 1] or p1
    local next = i < #path - 1 and path[i + 2] or p2
    
    local c1 = p1 + (p2 - prev) * factor
    local c2 = p2 - (next - p1) * factor
    
    return c1, c2
end

-- Cubic Bezier point
function SplineAlgorithms._cubic_bezier_point(p0, p1, p2, p3, t)
    local u = 1 - t
    local u2 = u * u
    local u3 = u2 * u
    local t2 = t * t
    local t3 = t2 * t
    
    return p0 * u3 + p1 * (3 * u2 * t) + p2 * (3 * u * t2) + p3 * t3
end

return SplineAlgorithms