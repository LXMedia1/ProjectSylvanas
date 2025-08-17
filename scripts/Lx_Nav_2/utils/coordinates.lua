-- Coordinate System Utilities

local vec3 = require('common/geometry/vector_3')

local Coordinates = {}

local TILE_SIZE = 533.33333
local HALF_WORLD = 32 * TILE_SIZE -- 64x64 tile grid centered

-- Convert Recast mesh coordinates to game coordinates
-- Recast: x=forward, y=up, z=right
-- Game: x=north/south, y=east/west, z=up/down
-- Mapping: x_game = z_mesh, y_game = x_mesh, z_game = y_mesh
function Coordinates.mesh_to_game(mesh_x, mesh_y, mesh_z)
    return mesh_z, mesh_x, mesh_y
end

-- Convert game coordinates to Recast mesh coordinates
function Coordinates.game_to_mesh(game_x, game_y, game_z)
    return game_y, game_z, game_x
end

-- Convert vec3 from mesh to game coordinates
function Coordinates.vec3_mesh_to_game(mesh_pos)
    local mx, my, mz = mesh_pos:unpack()
    return vec3.new(Coordinates.mesh_to_game(mx, my, mz))
end

-- Convert vec3 from game to mesh coordinates
function Coordinates.vec3_game_to_mesh(game_pos)
    local gx, gy, gz = game_pos:unpack()
    return vec3.new(Coordinates.game_to_mesh(gx, gy, gz))
end

-- Get tile coordinates from world position
function Coordinates.world_to_tile(x, y)
    local tile_x = math.floor((HALF_WORLD - x) / TILE_SIZE)
    local tile_y = math.floor((HALF_WORLD - y) / TILE_SIZE)
    if tile_x < 0 then tile_x = 0 elseif tile_x > 63 then tile_x = 63 end
    if tile_y < 0 then tile_y = 0 elseif tile_y > 63 then tile_y = 63 end
    return tile_x, tile_y
end

-- Get world coordinates from tile coordinates
function Coordinates.tile_to_world(tile_x, tile_y)
    local min_x = HALF_WORLD - (tile_x + 1) * TILE_SIZE
    local max_y = HALF_WORLD - tile_y * TILE_SIZE
    -- Return corner representative (min_x, max_y)
    return min_x, max_y
end

-- Quantize position to grid (0.35m resolution)
function Coordinates.quantize(x, y, z)
    local QUANT = 0.35
    return 
        math.floor(x / QUANT + 0.5) * QUANT,
        math.floor(y / QUANT + 0.5) * QUANT,
        math.floor(z / QUANT + 0.5) * QUANT
end

-- Check if position is near tile boundary
function Coordinates.near_tile_boundary(x, y, threshold)
    threshold = threshold or 50
    local TILE_SIZE = 533.33333
    local tx = x % TILE_SIZE
    local ty = y % TILE_SIZE
    
    return tx < threshold or tx > (TILE_SIZE - threshold) or
           ty < threshold or ty > (TILE_SIZE - threshold)
end

return Coordinates