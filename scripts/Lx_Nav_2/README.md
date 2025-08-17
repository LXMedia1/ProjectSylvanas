# Lx_Nav_2 - Modular Navigation System

## Overview

Lx_Nav_2 is a complete rewrite of the original Lx_Nav system with a clean, modular architecture. Every file is under 500 lines, promoting maintainability and readability.

## Architecture

### Core Components

- **NavigationManager** (`core/`) - Central orchestrator that manages all subsystems
- **TileManager** (`mesh/`) - Handles loading and caching of navigation mesh tiles  
- **PolygonExtractor** (`mesh/`) - Extracts walkable polygons from mesh data
- **GraphBuilder** (`pathfinding/`) - Builds navigation graphs with incremental processing
- **AStar** (`pathfinding/`) - A* pathfinding with support for alternative paths
- **PathSmoother** (`pathfinding/`) - Path optimization and smoothing algorithms
- **MovementController** (`movement/`) - Handles actual player movement along paths

### Directory Structure

```
Lx_Nav_2/
├── api/           # Public API layer
├── config/        # Configuration and settings
├── core/          # Core navigation manager
├── mesh/          # Mesh parsing and tile management
├── movement/      # Movement control
├── pathfinding/   # Pathfinding algorithms
├── rendering/     # Debug visualization
└── utils/         # Utility modules
```

## Key Improvements

### 1. Modular Design
- Each component has a single responsibility
- Clean interfaces between modules
- Easy to test and maintain individual components

### 2. File Size Management
- No file exceeds 500 lines (largest is 327 lines)
- Complex logic split into focused modules
- Better organization and navigation

### 3. Advanced Smoothing System
- **11 different smoothing algorithms** available
- Spline-based: Chaikin, B-Splines, Catmull-Rom, Centripetal Catmull-Rom, Cubic Hermite, Bezier
- Filter-based: Moving Average, Gaussian, Savitzky-Golay, Laplacian
- Geometric: Douglas-Peucker simplification
- Runtime algorithm switching for testing

### 4. Configuration System
- Centralized settings in `config/settings.lua`
- Runtime configuration changes
- Dot notation for nested settings
- Method-specific parameter tuning

### 5. Performance Optimizations
- Incremental graph building with time budgets
- Efficient tile loading and caching
- Memory-conscious polygon extraction

### 6. Enhanced API
- Backward compatible with original Lx_Nav
- Additional configuration options
- Better debugging and visualization
- Individual algorithm access for testing

## Usage

### Basic Setup
```lua
-- Initialize navigation system
local nav = _G.Lx_Nav_2.init()

-- Enable debug features
nav.set_debug(true)
nav.set_show_path(true)

-- Move to a position
nav.move_to(target_position, false, function()
    print("Movement completed")
end)
```

### Advanced Configuration
```lua
-- Configure pathfinding
nav.set_path_weights(0.3, 1.5)  -- clearance, layer weights

-- Configure smoothing method
nav.set_smoothing_method("catmull_rom")  -- Choose algorithm
nav.set_smoothing_params({
    catmull_rom_tension = 0.3,
    catmull_rom_resolution = 0.1,
    pre_simplify = true,
    simplify_tolerance = 2.0
})

-- Configure tiles
nav.set_tile_radius(3, 4)  -- load radius, keep radius

-- Configure movement
nav.set_movement_options(1.0, 3.0, true)  -- arrive distance, stuck threshold, humanize
```

### Smoothing Algorithm Testing
```lua
-- Get all available methods
local methods = nav.get_smoothing_methods()

-- Test different algorithms
for name, method in pairs(methods) do
    nav.set_smoothing_method(method)
    print("Testing:", name)
    
    -- Test movement with this algorithm
    nav.move_to(target_position)
end

-- Interactive testing helper
local test = require('test_smoothing')
local nav, switch_method = test.interactive()

-- Switch methods during runtime
switch_method()  -- Cycles to next algorithm
```

## API Compatibility

Lx_Nav_2 maintains API compatibility with the original Lx_Nav:

- `move_to(position, direct, callback)` - Move to position
- `stop()` - Stop movement
- `get_path(start, end)` - Get path between points
- `set_debug(enabled)` - Enable debug mode
- `set_show_path(enabled)` - Show path visualization

## Performance

The modular design allows for better performance:

- **Incremental Loading**: Tiles loaded progressively with time budgets
- **Smart Caching**: Parsed tiles cached to avoid re-parsing
- **Efficient Pathfinding**: A* with early termination and heuristics
- **Smooth Movement**: Path smoothing reduces computation overhead

## Debugging

Enhanced debugging capabilities:

- Path visualization with distance markers
- Navigation mesh rendering
- Tile boundary display
- Performance profiling
- Detailed logging system

## File Size Compliance

All files adhere to the 500-line limit:

| Component | Lines | Purpose |
|-----------|-------|---------|
| main.lua | 19 | Entry point |
| header.lua | 21 | Plugin metadata |
| logger.lua | 52 | Logging utilities |
| coordinates.lua | 64 | Coordinate transforms |
| profiler.lua | 91 | Performance monitoring |
| settings.lua | 96 | Configuration system |
| binary_reader.lua | 112 | Binary data parsing |
| path_renderer.lua | 141 | Path visualization |
| tile_manager.lua | 194 | Tile loading/management |
| mesh_renderer.lua | 196 | Mesh visualization |
| polygon_extractor.lua | 199 | Polygon processing |
| public_api.lua | 210 | Public interface |
| tile_parser.lua | 217 | Mesh tile parsing |
| path_smoother.lua | 258 | Path optimization |
| movement_controller.lua | 294 | Movement control |
| astar.lua | 302 | A* pathfinding |
| navigation_manager.lua | 326 | Core coordinator |
| graph_builder.lua | 327 | Graph construction |

**Total: 3,119 lines** (vs. 3,721 in original)

The new structure is not only better organized but also slightly more compact while providing significantly more functionality and maintainability.