-- Tile Loading and Management

local TileParser = require('mesh/tile_parser')
local Coordinates = require('utils/coordinates')
local Settings = require('config/settings')
local Logger = require('utils/logger')
local Coordinates = require('utils/coordinates')
local Profiler = require('utils/profiler')

local TileManager = {}
TileManager.__index = TileManager

function TileManager:new()
    local obj = {
        loaded_tiles = {},      -- map "x:y" -> true
        tiles = {},            -- map "x:y" -> tile_data
        tile_cache = {},       -- filename -> parsed data
        queued_set = {},       -- key -> true (currently enqueued)
        current_instance = nil,
        load_queue = {},       -- tiles pending load
        load_timer = Profiler.Timer:new(),
        -- Instance header
        origin_x = 0.0,
        origin_y = 0.0,
        origin_z = 0.0,
        tile_width = 533.33333,
        tile_height = 533.33333,
        max_tiles = 64,
        max_polys = 0
    }
    setmetatable(obj, self)
    return obj
end

-- Format tile filename
function TileManager:format_filename(continent_id, tile_x, tile_y)
    -- Match Lx_Nav format: mmaps/{id}{xx}{yy}.mmtile with zero-padded two-digit indices
    local id_str = string.format("%04d", continent_id)
    local x_str = string.format("%02d", tile_x)
    local y_str = string.format("%02d", tile_y)
    return "mmaps/" .. id_str .. x_str .. y_str .. ".mmtile"
end

-- Read instance .mmap header to get origin and tile sizes
local function _read_u32_val(data, pos)
    local b1 = string.byte(data, pos) or 0
    local b2 = string.byte(data, pos + 1) or 0
    local b3 = string.byte(data, pos + 2) or 0
    local b4 = string.byte(data, pos + 3) or 0
    return b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
end

local function _read_f32_val(data, pos)
    local bits = _read_u32_val(data, pos)
    if bits == 0 then return 0.0 end
    local sign = 1
    if bits >= 2147483648 then
        sign = -1
        bits = bits - 2147483648
    end
    local exp = math.floor(bits / 8388608)
    bits = bits - exp * 8388608
    local mant = bits / 8388608
    if exp == 0 then
        if mant == 0 then return sign * 0 end
        return sign * mant * 2^(-126)
    elseif exp == 255 then
        return sign * math.huge
    end
    return sign * (1 + mant) * 2^(exp - 127)
end

function TileManager:load_instance_header(continent_id)
    local mmap_name = string.format("mmaps/%04d.mmap", continent_id)
    local data = core.read_data_file and core.read_data_file(mmap_name)
    if not data or #data < 28 then
        Logger:warning("Missing or invalid mmap header: " .. mmap_name)
        return false
    end
    local pos = 1
    self.origin_x = _read_f32_val(data, pos); pos = pos + 4
    self.origin_y = _read_f32_val(data, pos); pos = pos + 4
    self.origin_z = _read_f32_val(data, pos); pos = pos + 4
    self.tile_width = _read_f32_val(data, pos); pos = pos + 4
    self.tile_height = _read_f32_val(data, pos); pos = pos + 4
    self.max_tiles = _read_u32_val(data, pos); pos = pos + 4
    self.max_polys = _read_u32_val(data, pos); pos = pos + 4
    if Settings.get('debug.tiles') then
        Logger:debug("Loaded mmap header: origin=(" .. tostring(self.origin_x) .. "," .. tostring(self.origin_y) .. "), tile=" .. tostring(self.tile_width))
    end
    return true
end

function TileManager:world_to_tile(world_x, world_y)
    -- Use the same 64x64 grid (0..63) as the loader's coordinate system
    return Coordinates.world_to_tile(world_x, world_y)
end

-- Get tile key for storage
function TileManager:get_tile_key(x, y)
    return string.format("%d:%d", x, y)
end

-- Load a single tile
function TileManager:load_tile(continent_id, tile_x, tile_y)
    -- Clamp tile indices defensively to 0..63
    if tile_x < 0 then tile_x = 0 elseif tile_x > 63 then tile_x = 63 end
    if tile_y < 0 then tile_y = 0 elseif tile_y > 63 then tile_y = 63 end
    local key = self:get_tile_key(tile_x, tile_y)
    
    -- Already loaded
    if self.loaded_tiles[key] then
        return true
    end
    
    local filename = self:format_filename(continent_id, tile_x, tile_y)
    local t0 = core.time()
    local c0 = (core.cpu_ticks and core.cpu_ticks()) or 0
    
    -- Check cache first
    local tile_data = self.tile_cache[filename]
    if tile_data == nil then
        -- Not in cache, try to load
        tile_data = TileParser.parse_tile_file(filename)
        if Settings.get("tiles.cache_enabled") then
            self.tile_cache[filename] = tile_data or false
        end
    elseif tile_data == false then
        -- Cached as missing
        return false
    end
    
    local parse_ms = nil
    if core.cpu_ticks and core.cpu_ticks_per_second then
        local dt_ticks = core.cpu_ticks() - c0
        parse_ms = (dt_ticks / core.cpu_ticks_per_second()) * 1000.0
    else
        parse_ms = (core.time() - t0)
    end
    if (Settings.get('debug.tiles') or Settings.get('debug.timing')) then
        Logger:debug("Tile load key=" .. key .. " file=" .. filename ..
                     " parse_ms=" .. string.format("%.3f", parse_ms) ..
                     " ok=" .. tostring(tile_data ~= nil))
    end

    if tile_data then
        self.tiles[key] = tile_data
        self.loaded_tiles[key] = true
        if Settings.get('debug.tiles') then
            Logger:debug("Loaded tile " .. key)
        end
        return true
    end
    
    return false
end

-- Queue tiles for loading
function TileManager:queue_tiles_around(continent_id, center_x, center_y, radius)
    local added = 0
    for dy = -radius, radius do
        for dx = -radius, radius do
            local tile_x = center_x + dx
            local tile_y = center_y + dy
            -- Clamp to 64x64 grid (0..63)
            if tile_x < 0 then tile_x = 0 elseif tile_x > 63 then tile_x = 63 end
            if tile_y < 0 then tile_y = 0 elseif tile_y > 63 then tile_y = 63 end
            local key = self:get_tile_key(tile_x, tile_y)
            
            if not self.loaded_tiles[key] and not self.queued_set[key] then
                -- Skip tiles known missing (cached as false)
                local filename = self:format_filename(continent_id, tile_x, tile_y)
                if self.tile_cache[filename] ~= false then
                    table.insert(self.load_queue, {
                        continent = continent_id,
                        x = tile_x,
                        y = tile_y,
                        key = key,
                        distance = math.max(math.abs(dx), math.abs(dy))
                    })
                    self.queued_set[key] = true
                    added = added + 1
                end
            end
        end
    end
    
    -- Sort by distance (load closer tiles first)
    if added > 0 then
        table.sort(self.load_queue, function(a, b)
            return a.distance < b.distance
        end)
    end
    
    return added
end

-- Queue a single tile (with dedupe and cache check)
function TileManager:queue_tile(continent_id, tile_x, tile_y, dx, dy)
    -- Clamp to 64x64 grid (0..63)
    if tile_x < 0 then tile_x = 0 elseif tile_x > 63 then tile_x = 63 end
    if tile_y < 0 then tile_y = 0 elseif tile_y > 63 then tile_y = 63 end
    local key = self:get_tile_key(tile_x, tile_y)
    if self.loaded_tiles[key] or self.queued_set[key] then return 0 end
    local filename = self:format_filename(continent_id, tile_x, tile_y)
    if self.tile_cache[filename] == false then return 0 end
    table.insert(self.load_queue, {
        continent = continent_id,
        x = tile_x,
        y = tile_y,
        key = key,
        distance = math.max(math.abs(dx or 0), math.abs(dy or 0))
    })
    self.queued_set[key] = true
    return 1
end

-- Queue only the newly required edge tiles when the center moves by <=1 tile in each axis
function TileManager:queue_tiles_delta(continent_id, old_x, old_y, new_x, new_y, radius)
    if not old_x or not old_y then
        return self:queue_tiles_around(continent_id, new_x, new_y, radius)
    end
    local dx = new_x - old_x
    local dy = new_y - old_y
    if (dx ~= 0 and math.abs(dx) > 1) or (dy ~= 0 and math.abs(dy) > 1) then
        return self:queue_tiles_around(continent_id, new_x, new_y, radius)
    end
    if dx == 0 and dy == 0 then return 0 end
    local added = 0
    if dx ~= 0 then
        local edge_x = new_x + (dx * radius)
        for yy = new_y - radius, new_y + radius do
            added = added + self:queue_tile(continent_id, edge_x, yy, math.abs(dx), math.abs(yy - new_y))
        end
    end
    if dy ~= 0 then
        local edge_y = new_y + (dy * radius)
        for xx = new_x - radius, new_x + radius do
            added = added + self:queue_tile(continent_id, xx, edge_y, math.abs(xx - new_x), math.abs(dy))
        end
    end
    return added
end

-- Process tile loading queue with budget
function TileManager:process_load_queue(budget_ms)
    if #self.load_queue == 0 then return 0 end
    
    local budget = Profiler.BudgetTracker:new(budget_ms)
    budget:start()
    
    local loaded = 0
    local step_t0 = core.time()
    local step_c0 = (core.cpu_ticks and core.cpu_ticks()) or 0
    local max_per_step = Settings.get('tiles.load_max_per_step') or 2
    local steps = 0
    while #self.load_queue > 0 and budget:has_budget() and steps < max_per_step do
        local tile = table.remove(self.load_queue, 1)
        if tile and tile.key then
            self.queued_set[tile.key] = nil
        end
        if self:load_tile(tile.continent, tile.x, tile.y) then
            loaded = loaded + 1
        end
        steps = steps + 1
    end
    local step_ms
    if core.cpu_ticks and core.cpu_ticks_per_second then
        step_ms = ((core.cpu_ticks() - step_c0) / core.cpu_ticks_per_second()) * 1000.0
    else
        step_ms = (core.time() - step_t0)
    end
    if (Settings.get('debug.tiles') or Settings.get('debug.timing')) then
        Logger:debug("Tile load step: loaded=" .. tostring(loaded) ..
                     " queue_left=" .. tostring(#self.load_queue) ..
                     " step_ms=" .. string.format("%.3f", step_ms))
    end

    return loaded
end

-- Evict tiles far from center
function TileManager:evict_far_tiles(center_x, center_y, keep_radius)
    local evicted = 0
    local to_remove = {}
    
    for key, _ in pairs(self.loaded_tiles) do
        local x, y = key:match("(-?%d+):(-?%d+)")
        x, y = tonumber(x), tonumber(y)
        
        local dist = math.max(math.abs(x - center_x), math.abs(y - center_y))
        if dist > keep_radius then
            table.insert(to_remove, key)
        end
    end
    
    for _, key in ipairs(to_remove) do
        self.loaded_tiles[key] = nil
        self.tiles[key] = nil
        evicted = evicted + 1
        if Settings.get('debug.eviction') or Settings.get('debug.tiles') then
            Logger:debug("Evicted tile " .. key)
        end
    end
    
    return evicted
end

-- Get all loaded tiles
function TileManager:get_loaded_tiles()
    local result = {}
    for key, tile_data in pairs(self.tiles) do
        if tile_data then
            table.insert(result, {
                key = key,
                data = tile_data
            })
        end
    end
    return result
end

-- Clear all tiles
function TileManager:clear()
    self.loaded_tiles = {}
    self.tiles = {}
    self.load_queue = {}
    if Settings.get('debug.tiles') then
        Logger:debug("Cleared all tiles")
    end
end

-- Clear cache
function TileManager:clear_cache()
    self.tile_cache = {}
    if Settings.get('debug.tiles') then
        Logger:debug("Cleared tile cache")
    end
end

-- Update instance (clear on change)
function TileManager:update_instance(instance_id)
    if self.current_instance ~= instance_id then
        self:clear()
        self.current_instance = instance_id
        Logger:info("Changed instance to " .. tostring(instance_id))
        self:load_instance_header(instance_id)
        return true
    end
    return false
end

-- Get tile at world position
function TileManager:get_tile_at(world_x, world_y)
    -- Use instance-aware conversion (origin, tile sizes from .mmap)
    local tile_x, tile_y = self:world_to_tile(world_x, world_y)
    local key = self:get_tile_key(tile_x, tile_y)
    return self.tiles[key]
end

-- Check if tile is loaded
function TileManager:is_tile_loaded(tile_x, tile_y)
    local key = self:get_tile_key(tile_x, tile_y)
    return self.loaded_tiles[key] == true
end

return TileManager