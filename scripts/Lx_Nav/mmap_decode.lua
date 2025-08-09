local MMap = {}

function MMap.new(orig_x, orig_y, orig_z, tile_width, tile_height, max_tiles, max_polys)
    local self = {}
    self.orig = {x = orig_x, y = orig_y, z = orig_z}
    self.tile_width = tile_width
    self.tile_height = tile_height
    self.max_tiles = max_tiles
    self.max_polys = max_polys
    return self
end

local function read_u32(data, pos)
    if not pos or not data then
        return nil, nil
    end
    if pos + 3 > #data then
        return nil, nil
    end
    local b1 = string.byte(data, pos)
    local b2 = string.byte(data, pos + 1)
    local b3 = string.byte(data, pos + 2)
    local b4 = string.byte(data, pos + 3)
    return b1 + b2 * 256 + b3 * 65536 + b4 * 16777216, pos + 4
end

local function read_u16(data, pos)
    if not pos or not data then
        return nil, nil
    end
    if pos + 1 > #data then
        return nil, nil
    end
    local b1 = string.byte(data, pos)
    local b2 = string.byte(data, pos + 1)
    return b1 + b2 * 256, pos + 2
end

local function read_f32(data, pos)
    local bits, new_pos = read_u32(data, pos)
    if not bits then
        return nil, nil
    end
    local sign = 1
    if bits >= 2^31 then
        sign = -1
        bits = bits - 2^31
    end
    local exp = math.floor(bits / 2^23)
    bits = bits - exp * 2^23
    local mant = bits / 2^23
    if exp == 0 then
        if mant == 0 then return sign * 0, new_pos end
        return sign * mant * 2^(-126), new_pos
    elseif exp == 0xFF then
        if mant == 0 then return sign * math.huge, new_pos end
        return 0/0, new_pos -- NaN
    end
    return sign * (1 + mant) * 2^(exp - 127), new_pos
end

-- Readers that do not change type of `pos` (increment separately)
local function read_u32_val(data, pos)
    local v = 0
    if pos and (pos + 3) <= #data then
        local b1 = string.byte(data, pos)
        local b2 = string.byte(data, pos + 1)
        local b3 = string.byte(data, pos + 2)
        local b4 = string.byte(data, pos + 3)
        v = b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
    end
    return v
end

local function read_f32_val(data, pos)
    local bits = read_u32_val(data, pos)
    if bits == 0 then return 0.0 end
    local sign = 1
    if bits >= 2^31 then
        sign = -1
        bits = bits - 2^31
    end
    local exp = math.floor(bits / 2^23)
    bits = bits - exp * 2^23
    local mant = bits / 2^23
    if exp == 0 then
        if mant == 0 then return sign * 0 end
        return sign * mant * 2^(-126)
    elseif exp == 0xFF then
        if mant == 0 then return sign * math.huge end
        return 0/0
    end
    return sign * (1 + mant) * 2^(exp - 127)
end

function MMap.parse(data)
    if #data < 28 then
        return nil, "Data too short for mmap"
    end
    local pos = 1
    local orig_x = read_f32_val(data, pos); pos = pos + 4
    local orig_y = read_f32_val(data, pos); pos = pos + 4
    local orig_z = read_f32_val(data, pos); pos = pos + 4
    local tile_width = read_f32_val(data, pos); pos = pos + 4
    local tile_height = read_f32_val(data, pos); pos = pos + 4
    local max_tiles = read_u32_val(data, pos); pos = pos + 4
    local max_polys = read_u32_val(data, pos); pos = pos + 4
    return MMap.new(orig_x, orig_y, orig_z, tile_width, tile_height, max_tiles, max_polys)
end

function MMap.parse_tile(data)
    if #data < 120 then -- Minimum size for both headers
        return nil, "Data too short for mmap tile"
    end

    local POLY_SIZE = 32
    local POLY_DETAIL_SIZE = 12
    local DETAIL_VERT_SIZE = 12
    local BVNODE_SIZE = 16
    local DETAIL_TRI_SIZE = 4
    local OFFMESH_CON_SIZE = 32
    local LINK_SIZE = 16

    local pos = 1
    local tile_data = {}

    -- MmapTileHeader (20 Byte)
    local mmap_magic = read_u32_val(data, pos); pos = pos + 4
    if mmap_magic ~= 0x4D4D4150 then -- 'MMAP'
        return nil, "Invalid mmap magic"
    end
    tile_data.dtVersion = read_u32_val(data, pos); pos = pos + 4
    tile_data.mmapVersion = read_u32_val(data, pos); pos = pos + 4
    tile_data.dataSize = read_u32_val(data, pos); pos = pos + 4
    tile_data.flags = read_u32_val(data, pos); pos = pos + 4

    -- dtMeshHeader (100 Byte)
    tile_data.meshMagic = read_u32_val(data, pos); pos = pos + 4
    tile_data.meshVersion = read_u32_val(data, pos); pos = pos + 4
    tile_data.tileX = read_u32_val(data, pos); pos = pos + 4
    tile_data.tileY = read_u32_val(data, pos); pos = pos + 4
    tile_data.layer = read_u32_val(data, pos); pos = pos + 4
    tile_data.userId = read_u32_val(data, pos); pos = pos + 4
    tile_data.polyCount = read_u32_val(data, pos); pos = pos + 4
    tile_data.vertCount = read_u32_val(data, pos); pos = pos + 4
    tile_data.maxLinkCount = read_u32_val(data, pos); pos = pos + 4
    tile_data.detailMeshCount = read_u32_val(data, pos); pos = pos + 4
    tile_data.detailVertCount = read_u32_val(data, pos); pos = pos + 4
    tile_data.detailTriCount = read_u32_val(data, pos); pos = pos + 4
    tile_data.bvNodeCount = read_u32_val(data, pos); pos = pos + 4
    tile_data.offMeshConCount = read_u32_val(data, pos); pos = pos + 4
    tile_data.offMeshBase = read_u32_val(data, pos); pos = pos + 4
    tile_data.walkableHeight = read_f32_val(data, pos); pos = pos + 4
    tile_data.walkableRadius = read_f32_val(data, pos); pos = pos + 4
    tile_data.walkableClimb = read_f32_val(data, pos); pos = pos + 4

    tile_data.bmin = {}
    tile_data.bmin.x = read_f32_val(data, pos); pos = pos + 4
    tile_data.bmin.y = read_f32_val(data, pos); pos = pos + 4
    tile_data.bmin.z = read_f32_val(data, pos); pos = pos + 4

    tile_data.bmax = {}
    tile_data.bmax.x = read_f32_val(data, pos); pos = pos + 4
    tile_data.bmax.y = read_f32_val(data, pos); pos = pos + 4
    tile_data.bmax.z = read_f32_val(data, pos); pos = pos + 4

    tile_data.bvQuantFactor = read_f32_val(data, pos); pos = pos + 4

    -- Vertices: vertCount * 3 * float
    tile_data.vertices = {}
    for i = 1, tile_data.vertCount * 3 do
        local val = read_f32_val(data, pos); pos = pos + 4
        table.insert(tile_data.vertices, val)
    end

    -- Polys
    local bytes_to_read = tile_data.polyCount * POLY_SIZE
    if pos + bytes_to_read -1 > #data then return nil, "Data too short for polys. Expected: " .. bytes_to_read .. ", Remaining: " .. (#data - pos + 1) end
    tile_data.polys_raw = string.sub(data, pos, pos + bytes_to_read - 1)
    pos = pos + bytes_to_read

    -- PolyDetail
    bytes_to_read = tile_data.detailMeshCount * POLY_DETAIL_SIZE
    if pos + bytes_to_read -1 > #data then return nil, "Data too short for poly details. Expected: " .. bytes_to_read .. ", Remaining: " .. (#data - pos + 1) end
    tile_data.detailMeshes_raw = string.sub(data, pos, pos + bytes_to_read - 1)
    pos = pos + bytes_to_read

    -- DetailVerts (packed uint32)
    tile_data.detailVerts = {}
    local function dequant16(q, min, max)
        local upper16 = math.floor(q / 65536)
        return min + (upper16 / 65535.0) * (max - min)
    end
    for i = 1, tile_data.detailVertCount do
        local x, y, z
        x = read_u32_val(data, pos); pos = pos + 4
        y = read_u32_val(data, pos); pos = pos + 4
        z = read_u32_val(data, pos); pos = pos + 4
        table.insert(tile_data.detailVerts, {x = x or 0, y = y or 0, z = z or 0})
    end
    tile_data.getDetailVertWorld = function(i)
        local v = tile_data.detailVerts[i]
        return dequant16(v.x, tile_data.bmin.x, tile_data.bmax.x),
               dequant16(v.y, tile_data.bmin.y, tile_data.bmax.y),
               dequant16(v.z, tile_data.bmin.z, tile_data.bmax.z)
    end

    -- DetailTris
    bytes_to_read = tile_data.detailTriCount * DETAIL_TRI_SIZE
    if pos + bytes_to_read -1 > #data then return nil, "Data too short for detail tris. Expected: " .. bytes_to_read .. ", Remaining: " .. (#data - pos + 1) end
    tile_data.detailTris_raw = string.sub(data, pos, pos + bytes_to_read - 1)
    pos = pos + bytes_to_read

    -- BVNodes
    bytes_to_read = tile_data.bvNodeCount * BVNODE_SIZE
    if pos + bytes_to_read -1 > #data then return nil, "Data too short for BV nodes. Expected: " .. bytes_to_read .. ", Remaining: " .. (#data - pos + 1) end
    tile_data.bvNodes_raw = string.sub(data, pos, pos + bytes_to_read - 1)
    pos = pos + bytes_to_read

    -- OffMeshCons
    bytes_to_read = tile_data.offMeshConCount * OFFMESH_CON_SIZE
    if pos + bytes_to_read -1 > #data then return nil, "Data too short for off-mesh connections. Expected: " .. bytes_to_read .. ", Remaining: " .. (#data - pos + 1) end
    tile_data.offMeshCons_raw = string.sub(data, pos, pos + bytes_to_read -  1)
    pos = pos + bytes_to_read

    -- Links
    bytes_to_read = tile_data.maxLinkCount * LINK_SIZE
    if pos + bytes_to_read -1 > #data then return nil, "Data too short for links. Expected: " .. bytes_to_read .. ", Remaining: " .. (#data - pos + 1) end
    tile_data.links_raw = string.sub(data, pos, pos + bytes_to_read - 1)
    pos = pos + bytes_to_read

    local consumed = pos - 21
    if consumed ~= tile_data.dataSize then
        return nil, string.format("Size mismatch: consumed %d bytes, expected %d bytes (dataSize)", consumed, tile_data.dataSize)
    end

    return tile_data
end

local function read_binary_file(path)
    local data = core.read_data_file(path)
    if not data or #data == 0 then return nil end
    return data
end

function MMap.load()
    local instance_id = core.get_instance_id() or 0
    local id = string.format("%04d", instance_id)
    local filename = id .. ".mmap"
    local data = read_binary_file("mmaps/" .. filename)
    if not data then
        core.log("Failed to load " .. filename)
        return nil
    end
    core.log("Loaded " .. filename .. " - Size: " .. #data .. " bytes")
    local mmap, err = MMap.parse(data)
    if err then
        core.log("Parse error: " .. err)
        return nil
    end
    return mmap
end

return MMap
