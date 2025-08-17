-- Test Script for All Smoothing Methods

local vec3 = require('common/geometry/vector_3')

-- Example usage of all smoothing methods
local function test_all_smoothing_methods()
    -- Initialize navigation
    local nav = _G.Lx_Nav_2.init()
    
    -- Enable debug features
    nav.set_debug(true)
    nav.set_show_path(true)
    
    -- Get available methods
    local methods = nav.get_smoothing_methods()
    
    print("Available smoothing methods:")
    for name, method in pairs(methods) do
        print("  " .. name .. " -> " .. method)
    end
    
    -- Test each method
    print("\n=== Testing Smoothing Methods ===")
    
    -- 1. Chaikin's Corner Cutting
    print("\n1. Testing Chaikin's Corner Cutting (Classic)")
    nav.set_smoothing_method("chaikin")
    nav.set_smoothing_params({
        iterations = 3,
        pre_simplify = false,
        apply_turn_radius = false
    })
    print("  - Fast, cartoon-like smoothing")
    print("  - Good for: Quick responsive movement")
    
    -- 2. B-Splines
    print("\n2. Testing Uniform Cubic B-Splines")
    nav.set_smoothing_method("bspline")
    nav.set_smoothing_params({
        bspline_resolution = 0.1
    })
    print("  - Very smooth, CAD-like")
    print("  - Good for: Graphics, smooth camera paths")
    
    -- 3. Catmull-Rom
    print("\n3. Testing Catmull-Rom Splines")
    nav.set_smoothing_method("catmull_rom")
    nav.set_smoothing_params({
        catmull_rom_tension = 0.5,
        catmull_rom_resolution = 0.1
    })
    print("  - Interpolating (passes through points)")
    print("  - Good for: Animation paths, data visualization")
    
    -- 4. Centripetal Catmull-Rom
    print("\n4. Testing Centripetal Catmull-Rom")
    nav.set_smoothing_method("centripetal_catmull_rom")
    nav.set_smoothing_params({
        centripetal_alpha = 0.5,
        centripetal_resolution = 0.1
    })
    print("  - Fixes overshooting problems")
    print("  - Good for: Fair curves through noisy data")
    
    -- 5. Cubic Hermite (PCHIP)
    print("\n5. Testing Cubic Hermite Splines (PCHIP)")
    nav.set_smoothing_method("cubic_hermite")
    nav.set_smoothing_params({
        hermite_resolution = 0.1
    })
    print("  - Monotonicity preserving")
    print("  - Good for: Scientific visualization, avoiding wiggles")
    
    -- 6. Bezier Splines
    print("\n6. Testing Bezier Splines")
    nav.set_smoothing_method("bezier")
    nav.set_smoothing_params({
        bezier_control_factor = 0.3
    })
    print("  - Parametric curves with control points")
    print("  - Good for: Vector graphics, flexible control")
    
    -- 7. Moving Average
    print("\n7. Testing Moving Average")
    nav.set_smoothing_method("moving_average")
    nav.set_smoothing_params({
        moving_average_window = 3
    })
    print("  - Simple denoising")
    print("  - Good for: Fast, preserving general shape")
    
    -- 8. Gaussian Smoothing
    print("\n8. Testing Gaussian Kernel Smoothing")
    nav.set_smoothing_method("gaussian")
    nav.set_smoothing_params({
        gaussian_sigma = 1.0,
        gaussian_kernel_size = 5
    })
    print("  - Gaussian-weighted averaging")
    print("  - Good for: Signal processing, natural smoothing")
    
    -- 9. Savitzky-Golay
    print("\n9. Testing Savitzky-Golay Filter")
    nav.set_smoothing_method("savitzky_golay")
    nav.set_smoothing_params({
        savgol_window = 5,
        savgol_order = 2
    })
    print("  - Polynomial smoothing")
    print("  - Good for: Scientific data, preserving features")
    
    -- 10. Laplacian Smoothing
    print("\n10. Testing Laplacian Smoothing")
    nav.set_smoothing_method("laplacian")
    nav.set_smoothing_params({
        laplacian_lambda = 0.5,
        iterations = 3
    })
    print("  - Spring relaxation")
    print("  - Good for: Mesh smoothing, topology preservation")
    
    -- 11. Douglas-Peucker
    print("\n11. Testing Douglas-Peucker Simplification")
    nav.set_smoothing_method("douglas_peucker")
    nav.set_smoothing_params({
        simplify_tolerance = 3.0
    })
    print("  - Geometric simplification")
    print("  - Good for: Reducing path complexity")
    
    -- Combination examples
    print("\n=== Combination Examples ===")
    
    print("\nFor Game Movement (Responsive):")
    nav.set_smoothing_method("moving_average")
    nav.set_smoothing_params({
        moving_average_window = 2,
        apply_turn_radius = true,
        turn_radius = 1.0
    })
    
    print("\nFor Cinematic Paths (Smooth):")
    nav.set_smoothing_method("catmull_rom")
    nav.set_smoothing_params({
        catmull_rom_tension = 0.3,
        catmull_rom_resolution = 0.05,
        pre_simplify = true,
        simplify_tolerance = 2.0
    })
    
    print("\nFor Noisy Data (Robust):")
    nav.set_smoothing_method("gaussian")
    nav.set_smoothing_params({
        gaussian_sigma = 1.5,
        gaussian_kernel_size = 7,
        pre_simplify = true
    })
    
    return nav
end

-- Interactive method switching
local function setup_interactive_testing()
    local nav = _G.Lx_Nav_2.init()
    nav.set_debug(true)
    nav.set_show_path(true)
    
    local current_method = 1
    local method_list = {
        "chaikin",
        "bspline", 
        "catmull_rom",
        "centripetal_catmull_rom",
        "cubic_hermite",
        "bezier",
        "moving_average",
        "gaussian",
        "savitzky_golay",
        "laplacian",
        "douglas_peucker"
    }
    
    local method_descriptions = {
        "Chaikin's Corner Cutting (Fast, cartoon-like)",
        "B-Splines (Very smooth, CAD-like)",
        "Catmull-Rom (Interpolating, animation)",
        "Centripetal Catmull-Rom (No overshooting)",
        "Cubic Hermite/PCHIP (Monotonic, scientific)",
        "Bezier Splines (Control points, graphics)",
        "Moving Average (Simple, fast denoising)",
        "Gaussian (Signal processing, natural)",
        "Savitzky-Golay (Polynomial, feature preserving)",
        "Laplacian (Spring relaxation, mesh)",
        "Douglas-Peucker (Simplification only)"
    }
    
    -- Switch to next method
    function switch_method()
        current_method = (current_method % #method_list) + 1
        local method = method_list[current_method]
        local description = method_descriptions[current_method]
        
        nav.set_smoothing_method(method)
        print(string.format("Switched to: %s - %s", method, description))
        
        return method
    end
    
    -- Initial setup
    local initial_method = switch_method()
    print("Interactive testing setup complete!")
    print("Call switch_method() to cycle through smoothing algorithms")
    
    return nav, switch_method
end

-- Performance comparison
local function performance_test()
    local vec3 = require('common/geometry/vector_3')
    
    -- Create test path
    local test_path = {}
    for i = 1, 20 do
        table.insert(test_path, vec3:new(
            i * 5 + math.random() * 3,
            math.sin(i * 0.5) * 10 + math.random() * 2,
            math.random() * 1
        ))
    end
    
    local PathSmoother = require('pathfinding/path_smoother')
    local methods = PathSmoother.METHODS
    
    print("Performance Test Results:")
    print("Input path: " .. #test_path .. " points")
    
    for name, method in pairs(methods) do
        local start_time = os.clock()
        local smoothed = PathSmoother.smooth(test_path, method)
        local end_time = os.clock()
        
        local duration = (end_time - start_time) * 1000 -- Convert to ms
        local output_points = smoothed and #smoothed or 0
        
        print(string.format("  %s: %.2fms, %d -> %d points", 
                           name, duration, #test_path, output_points))
    end
end

-- Export functions for use
return {
    test_all = test_all_smoothing_methods,
    interactive = setup_interactive_testing,
    performance = performance_test
}