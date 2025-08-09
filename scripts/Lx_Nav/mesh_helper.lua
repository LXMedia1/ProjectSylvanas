local mesh_helper = {}

-- WoW coordinate system constants
mesh_helper.tile_size = 533.33333
mesh_helper.HALF_WORLD = 32 * mesh_helper.tile_size  -- Center as 32 * tile_size
mesh_helper.MAX_INDEX = 63               -- 0-63 range (64 tiles total)

function mesh_helper.get_tile_coordinates(x, y)
    -- WoW coordinate system: Y is west↔east, so invert by subtracting from HALF_WORLD
    local tile_x = math.floor((mesh_helper.HALF_WORLD - x) / mesh_helper.tile_size)
    local tile_y = math.floor((mesh_helper.HALF_WORLD - y) / mesh_helper.tile_size)

    -- Clamp to valid range (0-63)
    tile_x = math.max(0, math.min(mesh_helper.MAX_INDEX, tile_x))
    tile_y = math.max(0, math.min(mesh_helper.MAX_INDEX, tile_y))

    return tile_x, tile_y
end

return mesh_helper