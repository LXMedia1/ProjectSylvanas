-- Filter-based Smoothing Algorithms

local vec3 = require('common/geometry/vector_3')
local Settings = require('config/settings')

local FilterAlgorithms = {}

-- 7. Moving Average Smoothing
function FilterAlgorithms.moving_average(path, window_size)
    if #path < 3 then return path end
    
    window_size = window_size or Settings.get("smoothing.moving_average_window") or 3
    local result = {}
    
    for i = 1, #path do
        local sum = vec3.new(0, 0, 0)
        local count = 0
        
        local start = math.max(1, i - math.floor(window_size / 2))
        local finish = math.min(#path, i + math.floor(window_size / 2))
        
        for j = start, finish do
            sum = sum + path[j]
            count = count + 1
        end
        
        table.insert(result, sum / count)
    end
    
    return result
end

-- 8. Gaussian Kernel Smoothing
function FilterAlgorithms.gaussian_smoothing(path, sigma, kernel_size)
    if #path < 3 then return path end
    
    sigma = sigma or Settings.get("smoothing.gaussian_sigma") or 1.0
    kernel_size = kernel_size or Settings.get("smoothing.gaussian_kernel_size") or 5
    
    -- Generate Gaussian kernel
    local kernel = FilterAlgorithms._generate_gaussian_kernel(kernel_size, sigma)
    local result = {}
    
    for i = 1, #path do
        local weighted_sum = vec3.new(0, 0, 0)
        local weight_sum = 0
        
        for j = 1, kernel_size do
            local idx = i - math.floor(kernel_size / 2) + j - 1
            if idx >= 1 and idx <= #path then
                weighted_sum = weighted_sum + path[idx] * kernel[j]
                weight_sum = weight_sum + kernel[j]
            end
        end
        
        table.insert(result, weighted_sum / weight_sum)
    end
    
    return result
end

-- 9. Savitzky-Golay Filter
function FilterAlgorithms.savitzky_golay(path, window_size, poly_order)
    if #path < 5 then return path end
    
    window_size = window_size or Settings.get("smoothing.savgol_window") or 5
    poly_order = poly_order or Settings.get("smoothing.savgol_order") or 2
    
    -- Ensure odd window size
    if window_size % 2 == 0 then window_size = window_size + 1 end
    
    local coeffs = FilterAlgorithms._calculate_savgol_coefficients(window_size, poly_order)
    local result = {}
    
    for i = 1, #path do
        local smoothed_point = vec3.new(0, 0, 0)
        local half_window = math.floor(window_size / 2)
        
        for j = -half_window, half_window do
            local idx = math.max(1, math.min(#path, i + j))
            smoothed_point = smoothed_point + path[idx] * coeffs[j + half_window + 1]
        end
        
        table.insert(result, smoothed_point)
    end
    
    return result
end

-- 10. Laplacian Smoothing
function FilterAlgorithms.laplacian_smoothing(path, iterations, lambda)
    if #path < 3 then return path end
    
    iterations = iterations or 3
    lambda = lambda or Settings.get("smoothing.laplacian_lambda") or 0.5
    
    local smoothed = {}
    for i = 1, #path do
        smoothed[i] = path[i]
    end
    
    for iter = 1, iterations do
        local new_path = {smoothed[1]} -- Keep endpoints fixed
        
        for i = 2, #smoothed - 1 do
            local neighbors = (smoothed[i - 1] + smoothed[i + 1]) / 2
            local laplacian = neighbors - smoothed[i]
            table.insert(new_path, smoothed[i] + laplacian * lambda)
        end
        
        table.insert(new_path, smoothed[#smoothed])
        smoothed = new_path
    end
    
    return smoothed
end

-- Helper function: Generate Gaussian kernel
function FilterAlgorithms._generate_gaussian_kernel(size, sigma)
    local kernel = {}
    local sum = 0
    local center = math.floor(size / 2) + 1
    
    for i = 1, size do
        local x = i - center
        local value = math.exp(-(x * x) / (2 * sigma * sigma))
        kernel[i] = value
        sum = sum + value
    end
    
    -- Normalize
    for i = 1, size do
        kernel[i] = kernel[i] / sum
    end
    
    return kernel
end

-- Helper function: Calculate Savitzky-Golay coefficients
function FilterAlgorithms._calculate_savgol_coefficients(window_size, poly_order)
    -- Simplified implementation - in practice you'd use proper matrix math
    local coeffs = {}
    local center = math.floor(window_size / 2) + 1
    
    -- Use a simple approximation for demo purposes
    for i = 1, window_size do
        local x = (i - center) / center
        local weight = 1 - math.abs(x)
        coeffs[i] = math.max(0, weight)
    end
    
    -- Normalize
    local sum = 0
    for i = 1, window_size do
        sum = sum + coeffs[i]
    end
    for i = 1, window_size do
        coeffs[i] = coeffs[i] / sum
    end
    
    return coeffs
end

return FilterAlgorithms