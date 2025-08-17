-- Navigation Mesh Tile Parser (MMAP) – compatible with Lx_Nav format

local Logger = require('utils/logger')
local Coordinates = require('utils/coordinates')

local TileParser = {}
local Settings = require('config/settings')

local function read_u32(data, pos)
    if not pos or not data or pos + 3 > #data then return nil, pos end
    local b1 = string.byte(data, pos)
    local b2 = string.byte(data, pos + 1)
    local b3 = string.byte(data, pos + 2)
    local b4 = string.byte(data, pos + 3)
    return b1 + b2 * 256 + b3 * 65536 + b4 * 16777216, pos + 4
end

local function read_f32(data, pos)
    local bits; bits, pos = read_u32(data, pos)
    if not bits then return nil, pos end
    local sign = 1
    if bits >= 2147483648 then
        sign = -1
        bits = bits - 2147483648
    end
    local exp = math.floor(bits / 8388608)
    bits = bits - exp * 8388608
    local mant = bits / 8388608
    if exp == 0 then
        if mant == 0 then return sign * 0, pos end
        return sign * mant * 2^(-126), pos
    elseif exp == 255 then
        return sign * math.huge, pos
    end
    return sign * (1 + mant) * 2^(exp - 127), pos
end

local function read_u16(data, pos)
    if not pos or not data or pos + 1 > #data then return nil, pos end
    local b1 = string.byte(data, pos)
    local b2 = string.byte(data, pos + 1)
    return b1 + b2 * 256, pos + 2
end

function TileParser.parse_tile(data)
    if not data or #data < 120 then
        Logger:error("Invalid tile data")
        return nil
    end

    local pos = 1
    -- MMAP magic
    local magic; magic, pos = read_u32(data, pos)
    if magic ~= 0x4D4D4150 then
        Logger:error("Invalid magic number: " .. string.format("0x%08X", magic or 0))
        return nil
    end

    -- MmapTileHeader: dtVersion, mmapVersion, dataSize, flags
    local dtVersion; dtVersion, pos = read_u32(data, pos)
    local mmVersion; mmVersion, pos = read_u32(data, pos)
    local dataSize; dataSize, pos = read_u32(data, pos)
    local flags; flags, pos = read_u32(data, pos)
    if dtVersion ~= 0x00000006 and dtVersion ~= 0x00000007 then
        Logger:warning("Unexpected version: " .. string.format("0x%08X", dtVersion or 0))
    end

    -- dtMeshHeader
    local header = {}
    header.meshMagic, pos = read_u32(data, pos)
    header.meshVersion, pos = read_u32(data, pos)
    header.x, pos = read_u32(data, pos)
    header.y, pos = read_u32(data, pos)
    header.layer, pos = read_u32(data, pos)
    header.userId, pos = read_u32(data, pos)
    header.polyCount, pos = read_u32(data, pos)
    header.vertCount, pos = read_u32(data, pos)
    header.maxLinkCount, pos = read_u32(data, pos)
    header.detailMeshCount, pos = read_u32(data, pos)
    header.detailVertCount, pos = read_u32(data, pos)
    header.detailTriCount, pos = read_u32(data, pos)
    header.bvNodeCount, pos = read_u32(data, pos)
    header.offMeshConCount, pos = read_u32(data, pos)
    header.offMeshBase, pos = read_u32(data, pos)
    header.walkableHeight, pos = read_f32(data, pos)
    header.walkableRadius, pos = read_f32(data, pos)
    header.walkableClimb, pos = read_f32(data, pos)
    header.bmin = {}; header.bmin[1], pos = read_f32(data, pos); header.bmin[2], pos = read_f32(data, pos); header.bmin[3], pos = read_f32(data, pos)
    header.bmax = {}; header.bmax[1], pos = read_f32(data, pos); header.bmax[2], pos = read_f32(data, pos); header.bmax[3], pos = read_f32(data, pos)
    header.bvQuantFactor, pos = read_f32(data, pos)

    -- Vertices: vertCount * 3 floats (flattened array like Lx_Nav)
    local vertices = {}
    for i = 1, header.vertCount do
        local mx, my, mz; mx, pos = read_f32(data, pos); my, pos = read_f32(data, pos); mz, pos = read_f32(data, pos)
        if not mx then return nil end
        local gx, gy, gz = Coordinates.mesh_to_game(mx, my, mz)
        table.insert(vertices, gx)
        table.insert(vertices, gy)
        table.insert(vertices, gz)
    end

    -- Polygons block: polyCount * 32 bytes
    local polygons = {}
    for i = 1, header.polyCount do
        local poly = {}
        poly.firstLink, pos = read_u32(data, pos)
        poly.verts = {}
        for j = 1, 6 do
            poly.verts[j], pos = read_u16(data, pos)
        end
        poly.neis = {}
        for j = 1, 6 do
            poly.neis[j], pos = read_u16(data, pos)
        end
        poly.flags, pos = read_u16(data, pos)
        local vc; vc, pos = read_u16(data, pos) -- two u8 packed LE: vertCount (low), areaAndtype (high)
        -- dtPoly stores: flags (u16), vertCount (u8), areaAndtype (u8)
        -- With little-endian reads, low byte is vertCount, high byte is area/type
        poly.vertCount = vc % 256
        poly.areaAndtype = math.floor(vc / 256)
        -- Debug one-liner per poly
        -- Logger:debug("Parser: poly id=" .. tostring(i) .. " vc=" .. tostring(poly.vertCount) .. " at=" .. tostring(poly.areaAndtype))
        polygons[i] = poly
    end

    return {
        header = header,
        vertices = vertices,
        polygons = polygons,
    }
end

function TileParser.parse_tile_file(filename)
    local data = core.read_data_file and core.read_data_file(filename)
    if not data or data == "" then
        if Settings and Settings.get and Settings.get('debug.tiles') then
            Logger:debug("Failed to read tile file: " .. filename)
        end
        return nil
    end
    return TileParser.parse_tile(data)
end

return TileParser