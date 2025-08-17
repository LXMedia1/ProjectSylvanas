-- Navigation Settings Configuration

local Settings = {
    -- Debug flags
    debug = {
        enabled = false,
        log_enabled = false,
        draw_path = false,
        draw_navmesh = false,
        draw_polygons = false,
        draw_corridor_layers = false,
        enhanced_visualization = false,
        -- Fine-grained debug categories
        extraction = false,
        merge = false,
        graph = false,
        tiles = false,
        eviction = false,
        timing = false,
    },
    
    -- Tile management
    tiles = {
        load_radius = 2,           -- Tiles to load around player
        keep_radius = 3,           -- Keep tiles within this radius
        load_budget_ms = 2.0,      -- Max time per frame for loading
        load_max_per_step = 1,     -- Max tiles parsed per frame
        cache_enabled = true,      -- Cache parsed tile data
        extract_budget_ms = 1.0,   -- Time budget per frame for extraction
        extract_max_per_step = 8,  -- Hard cap of tiles processed per frame (safety)
        rebuild_debounce_ms = 150, -- Wait after last tile load before rebuilding graph
    },
    
    -- Path finding
    pathfinding = {
        min_clearance = 1.5,       -- Minimum clearance from walls
        weight_clearance = 0.25,   -- Weight for clearance in cost
        weight_layer = 2.0,        -- Prefer same vertical layer
        max_iterations = 5000,     -- A* max iterations
        multi_path_count = 1,      -- Number of alternative paths
    },
    
    -- Path smoothing
    smoothing = {
        enabled = true,
        method = "chaikin",        -- Smoothing method to use
        iterations = 3,            -- Iterations for iterative methods
        pre_simplify = false,      -- Apply Douglas-Peucker first
        simplify_tolerance = 3.0,  -- Douglas-Peucker tolerance
        apply_turn_radius = false, -- Apply turn radius post-processing
        turn_radius = 2.0,         -- Turn radius for curves
        turn_segments = 4,         -- Segments per turn
        
        -- Method-specific parameters
        -- B-Spline
        bspline_resolution = 0.1,
        
        -- Catmull-Rom
        catmull_rom_tension = 0.5,
        catmull_rom_resolution = 0.1,
        
        -- Centripetal Catmull-Rom
        centripetal_alpha = 0.5,
        centripetal_resolution = 0.1,
        
        -- Cubic Hermite (PCHIP)
        hermite_resolution = 0.1,
        
        -- Bezier
        bezier_control_factor = 0.3,
        
        -- Moving Average
        moving_average_window = 3,
        
        -- Gaussian
        gaussian_sigma = 1.0,
        gaussian_kernel_size = 5,
        
        -- Savitzky-Golay
        savgol_window = 5,
        savgol_order = 2,
        
        -- Laplacian
        laplacian_lambda = 0.5,
    },
    
    -- Movement control
    movement = {
        arrive_distance = 1.5,     -- Distance to consider arrived
        stuck_threshold = 2.0,     -- Seconds before considered stuck
        stuck_distance = 0.5,      -- Min movement to not be stuck
        use_look_at = true,        -- Face movement direction
        humanize = true,           -- Add human-like movement
        humanize_factor = 0.15,    -- Random factor for humanization
    },
    
    -- Graph building
    graph = {
        batch_size = 600,          -- Nodes per batch
        target_batch_ms = 3.5,     -- Target time per batch
        min_batch = 200,           -- Minimum batch size
        max_batch = 1500,          -- Maximum batch size
        job_budget_ms = 8.0,       -- Time budget per frame
        max_steps_per_frame = 32,  -- Cap resumes per frame to avoid spikes
        fast_mode = true,          -- Use larger budgets for quicker builds
        ultra_mode = true,         -- Ultra-fast build: simplified costs during build
    },
    
    -- Rendering
    rendering = {
        -- Use 0..255 color components (matching Lx_Nav expectations)
        path_color = {50, 150, 255, 255},           -- Bright blue path
        alt_path_color = {255, 255, 0, 180},        -- Yellow alt paths
        polygon_color = {128, 128, 255, 80},        -- Light blue polygons
        navmesh_budget_ms = 1.5,               -- Navmesh draw budget
        path_draw_duration_ms = 300000,        -- 5 minutes
    },
}

-- Get setting value with dot notation (e.g., "debug.enabled")
function Settings.get(path)
    local current = Settings
    for part in string.gmatch(path, "[^%.]+") do
        current = current[part]
        if current == nil then return nil end
    end
    return current
end

-- Set setting value with dot notation
function Settings.set(path, value)
    local parts = {}
    for part in string.gmatch(path, "[^%.]+") do
        table.insert(parts, part)
    end
    
    local current = Settings
    for i = 1, #parts - 1 do
        current = current[parts[i]]
        if not current then return false end
    end
    
    current[parts[#parts]] = value
    return true
end

return Settings