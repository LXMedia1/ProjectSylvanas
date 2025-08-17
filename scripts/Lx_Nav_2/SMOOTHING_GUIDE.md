# Path Smoothing Guide for Lx_Nav_2

This guide explains how to test and configure all 11 available smoothing algorithms in Lx_Nav_2.

## Available Methods

### 1. Chaikin's Corner Cutting (Default)
**Best for:** Quick, cartoon-like smoothing
**Characteristics:** Fast, approximating (doesn't pass through original points)

```lua
local nav = _G.Lx_Nav_2.init()
nav.set_smoothing_method("chaikin")
nav.set_smoothing_params({
    iterations = 3  -- More iterations = smoother
})
```

### 2. Uniform Cubic B-Splines
**Best for:** CAD-like smoothing, graphics applications
**Characteristics:** Very smooth, natural generalization of Chaikin

```lua
nav.set_smoothing_method("bspline")
nav.set_smoothing_params({
    bspline_resolution = 0.1  -- Lower = more points
})
```

### 3. Catmull-Rom Splines
**Best for:** Animation paths, data visualization
**Characteristics:** Interpolating (passes through points), adjustable tension

```lua
nav.set_smoothing_method("catmull_rom")
nav.set_smoothing_params({
    catmull_rom_tension = 0.5,     -- 0.5 = cardinal spline
    catmull_rom_resolution = 0.1   -- Point density
})
```

### 4. Centripetal Catmull-Rom
**Best for:** Fair curves through noisy data
**Characteristics:** Fixes overshooting in standard Catmull-Rom

```lua
nav.set_smoothing_method("centripetal_catmull_rom")
nav.set_smoothing_params({
    centripetal_alpha = 0.5,       -- 0.0=uniform, 0.5=centripetal, 1.0=chordal
    centripetal_resolution = 0.1
})
```

### 5. Cubic Hermite Splines (PCHIP)
**Best for:** Scientific visualization, monotonic data
**Characteristics:** Preserves monotonicity, avoids unwanted wiggles

```lua
nav.set_smoothing_method("cubic_hermite")
nav.set_smoothing_params({
    hermite_resolution = 0.1
})
```

### 6. Bezier Splines
**Best for:** Vector graphics, flexible control
**Characteristics:** Parametric curves with control points

```lua
nav.set_smoothing_method("bezier")
nav.set_smoothing_params({
    bezier_control_factor = 0.3  -- Control point influence
})
```

### 7. Moving Average
**Best for:** Simple denoising, preserving general shape
**Characteristics:** Data-oriented, fast

```lua
nav.set_smoothing_method("moving_average")
nav.set_smoothing_params({
    moving_average_window = 3  -- Window size for averaging
})
```

### 8. Gaussian Kernel Smoothing
**Best for:** Signal processing, natural smoothing
**Characteristics:** Gaussian-weighted averaging

```lua
nav.set_smoothing_method("gaussian")
nav.set_smoothing_params({
    gaussian_sigma = 1.0,        -- Standard deviation
    gaussian_kernel_size = 5     -- Kernel size (odd number)
})
```

### 9. Savitzky-Golay Filter
**Best for:** Scientific data, preserving features
**Characteristics:** Polynomial smoothing, better shape preservation

```lua
nav.set_smoothing_method("savitzky_golay")
nav.set_smoothing_params({
    savgol_window = 5,  -- Window size (odd number)
    savgol_order = 2    -- Polynomial order
})
```

### 10. Laplacian Smoothing
**Best for:** Mesh smoothing, spring relaxation
**Characteristics:** Iterative "spring" relaxation

```lua
nav.set_smoothing_method("laplacian")
nav.set_smoothing_params({
    laplacian_lambda = 0.5,  -- Smoothing strength
    iterations = 3           -- Number of iterations
})
```

### 11. Douglas-Peucker Simplification
**Best for:** Path simplification, reducing points
**Characteristics:** Geometric simplification

```lua
nav.set_smoothing_method("douglas_peucker")
nav.set_smoothing_params({
    simplify_tolerance = 3.0  -- Distance tolerance
})
```

## Testing Different Methods

### Quick Test Setup
```lua
-- Initialize navigation
local nav = _G.Lx_Nav_2.init()
nav.set_debug(true)
nav.set_show_path(true)

-- Test different methods
local methods = nav.get_smoothing_methods()
for name, method in pairs(methods) do
    print("Testing method:", name)
    nav.set_smoothing_method(method)
    
    -- Move to test the smoothing
    nav.move_to(target_position)
    
    -- Wait for completion or manual interruption
    while nav.is_moving() do
        -- Update loop
    end
end
```

### Advanced Configuration
```lua
-- Combination approach: Simplify first, then smooth
nav.set_smoothing_params({
    pre_simplify = true,
    simplify_tolerance = 2.0,
    method = "catmull_rom",
    catmull_rom_tension = 0.3,
    apply_turn_radius = true,
    turn_radius = 1.5
})
```

## Recommended Use Cases

### For Game Movement
- **Fast/Responsive:** `moving_average` or `chaikin` (1-2 iterations)
- **Smooth/Natural:** `catmull_rom` or `centripetal_catmull_rom`
- **Sharp Corners:** `douglas_peucker` only

### For Cinematic Paths
- **Smooth Cameras:** `bspline` or `bezier`
- **Character Animation:** `catmull_rom` with high resolution
- **Vehicle Paths:** `centripetal_catmull_rom`

### For Navigation Data
- **Noisy GPS Data:** `gaussian` or `savitzky_golay`
- **Scientific Accuracy:** `cubic_hermite`
- **Mesh Optimization:** `laplacian`

## Performance Characteristics

**Fastest:** `moving_average`, `chaikin`, `douglas_peucker`
**Medium:** `gaussian`, `laplacian`
**Slower:** `catmull_rom`, `bspline`, `bezier`
**Slowest:** `cubic_hermite`, `savitzky_golay`, `centripetal_catmull_rom`

## Visual Comparison Script

```lua
-- Create test paths with each method
local test_path = {
    vec3:new(0, 0, 0),
    vec3:new(10, 5, 0),
    vec3:new(20, 3, 0),
    vec3:new(30, 8, 0),
    vec3:new(40, 2, 0)
}

local PathSmoother = require('pathfinding/path_smoother')

-- Test all methods
for name, method in pairs(PathSmoother.METHODS) do
    local smoothed = PathSmoother.smooth(test_path, method)
    print(string.format("%s: %d -> %d points", name, #test_path, #smoothed))
    
    -- Optionally draw or log the results
end
```

## Tips for Tuning

1. **Start with defaults** - Each method has sensible default parameters
2. **Adjust resolution first** - Lower values = more detailed curves
3. **Tune method-specific params** - Each has 1-2 key parameters to adjust
4. **Use pre-simplification** - For very jagged input paths
5. **Combine methods** - Douglas-Peucker + smoothing works well

## Real-time Method Switching

```lua
-- Bind keys to switch methods during testing
local current_method = 1
local method_list = {"chaikin", "bspline", "catmull_rom", "gaussian", "moving_average"}

function switch_smoothing_method()
    current_method = (current_method % #method_list) + 1
    local method = method_list[current_method]
    
    nav.set_smoothing_method(method)
    print("Switched to smoothing method:", method)
end
```

This guide provides a comprehensive overview of all smoothing options. Start with the defaults and experiment with different methods based on your specific use case!