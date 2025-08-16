local MMap = {}
local parsed_tile_cache = {}
local polygons_cache_by_transform = {}

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
    -- Parse dtPoly into structured tables
    tile_data.polys = {}
    do
        local raw = tile_data.polys_raw
        for i = 1, tile_data.polyCount do
            local base = (i - 1) * POLY_SIZE + 1
            if base + POLY_SIZE - 1 <= #raw then
                local p = base + 4 -- skip firstLink
                local verts, neis = {}, {}
                for j = 1, 6 do
                    local lo = string.byte(raw, p)
                    local hi = string.byte(raw, p + 1)
                    verts[j] = (lo or 0) + (hi or 0) * 256
                    p = p + 2
                end
                for j = 1, 6 do
                    local lo = string.byte(raw, p)
                    local hi = string.byte(raw, p + 1)
                    neis[j] = (lo or 0) + (hi or 0) * 256
                    p = p + 2
                end
                local flags = ((string.byte(raw, p) or 0) + (string.byte(raw, p + 1) or 0) * 256); p = p + 2
                local vertCount = string.byte(raw, p) or 0
                local areaAndtype = string.byte(raw, p + 1) or 0
                tile_data.polys[i] = {
                    id = i,
                    verts = verts,
                    neis = neis,
                    flags = flags,
                    vertCount = vertCount,
                    areaAndtype = areaAndtype,
                }
            end
        end
    end

    -- PolyDetail
    bytes_to_read = tile_data.detailMeshCount * POLY_DETAIL_SIZE
    if pos + bytes_to_read -1 > #data then return nil, "Data too short for poly details. Expected: " .. bytes_to_read .. ", Remaining: " .. (#data - pos + 1) end
    tile_data.detailMeshes_raw = string.sub(data, pos, pos + bytes_to_read - 1)
    pos = pos + bytes_to_read
    -- Parse dtPolyDetail meshes
    tile_data.detailMeshes = {}
    do
        local raw = tile_data.detailMeshes_raw
        for i = 1, tile_data.detailMeshCount do
            local base = (i - 1) * POLY_DETAIL_SIZE + 1
            if base + POLY_DETAIL_SIZE - 1 <= #raw then
                local vb = read_u32_val(raw, base)
                local tb = read_u32_val(raw, base + 4)
                local vc = string.byte(raw, base + 8) or 0
                local tc = string.byte(raw, base + 9) or 0
                tile_data.detailMeshes[i] = { vertBase = vb or 0, triBase = tb or 0, vertCount = vc, triCount = tc }
            end
        end
    end

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
        -- Guard against out-of-range indices
        if not i or i < 1 or i > (tile_data.detailVertCount or 0) then
            return nil, nil, nil
        end
        local v = tile_data.detailVerts[i]
        if not v then
            return nil, nil, nil
        end
        return dequant16(v.x, tile_data.bmin.x, tile_data.bmax.x),
               dequant16(v.y, tile_data.bmin.y, tile_data.bmax.y),
               dequant16(v.z, tile_data.bmin.z, tile_data.bmax.z)
    end

    -- DetailTris
    bytes_to_read = tile_data.detailTriCount * DETAIL_TRI_SIZE
    if pos + bytes_to_read -1 > #data then return nil, "Data too short for detail tris. Expected: " .. bytes_to_read .. ", Remaining: " .. (#data - pos + 1) end
    tile_data.detailTris_raw = string.sub(data, pos, pos + bytes_to_read - 1)
    pos = pos + bytes_to_read
    -- Parse dtDetailTri (each 4 bytes: v0,v1,v2,flags)
    tile_data.detailTris = {}
    do
        local raw = tile_data.detailTris_raw
        for i = 1, tile_data.detailTriCount do
            local base = (i - 1) * DETAIL_TRI_SIZE + 1
            if base + DETAIL_TRI_SIZE - 1 <= #raw then
                local v0 = string.byte(raw, base) or 0
                local v1 = string.byte(raw, base + 1) or 0
                local v2 = string.byte(raw, base + 2) or 0
                local f  = string.byte(raw, base + 3) or 0
                tile_data.detailTris[i] = { v0 = v0, v1 = v1, v2 = v2, flags = f }
            end
        end
    end

    -- BVNodes
    bytes_to_read = tile_data.bvNodeCount * BVNODE_SIZE
    if pos + bytes_to_read -1 > #data then return nil, "Data too short for BV nodes. Expected: " .. bytes_to_read .. ", Remaining: " .. (#data - pos + 1) end
    tile_data.bvNodes_raw = string.sub(data, pos, pos + bytes_to_read - 1)
    pos = pos + bytes_to_read
    -- Parse dtBVNode entries (int16 bmin[3], int16 bmax[3], int i)
    tile_data.bvNodes = {}
    do
        local raw = tile_data.bvNodes_raw
        for i = 1, tile_data.bvNodeCount do
            local base = (i - 1) * BVNODE_SIZE + 1
            if base + BVNODE_SIZE - 1 <= #raw then
                local function s16(off)
                    local lo = string.byte(raw, off) or 0
                    local hi = string.byte(raw, off + 1) or 0
                    local v = lo + hi * 256
                    if v >= 32768 then v = v - 65536 end
                    return v
                end
                local bmin0 = s16(base); local bmin1 = s16(base + 2); local bmin2 = s16(base + 4)
                local bmax0 = s16(base + 6); local bmax1 = s16(base + 8); local bmax2 = s16(base + 10)
                local idx = read_u32_val(raw, base + 12)
                tile_data.bvNodes[i] = { bmin = { bmin0, bmin1, bmin2 }, bmax = { bmax0, bmax1, bmax2 }, nodeId = idx or 0 }
            end
        end
    end

    -- OffMeshCons
    bytes_to_read = tile_data.offMeshConCount * OFFMESH_CON_SIZE
    if pos + bytes_to_read -1 > #data then return nil, "Data too short for off-mesh connections. Expected: " .. bytes_to_read .. ", Remaining: " .. (#data - pos + 1) end
    tile_data.offMeshCons_raw = string.sub(data, pos, pos + bytes_to_read -  1)
    pos = pos + bytes_to_read
    -- Parse dtOffMeshConnection entries
    tile_data.offMeshCons = {}
    do
        local raw = tile_data.offMeshCons_raw
        for i = 1, tile_data.offMeshConCount do
            local base = (i - 1) * OFFMESH_CON_SIZE + 1
            if base + OFFMESH_CON_SIZE - 1 <= #raw then
                local pos0 = {
                    read_f32_val(raw, base + 0),
                    read_f32_val(raw, base + 4),
                    read_f32_val(raw, base + 8),
                    read_f32_val(raw, base + 12),
                    read_f32_val(raw, base + 16),
                    read_f32_val(raw, base + 20),
                }
                local radius = read_f32_val(raw, base + 24)
                local flags  = read_u32_val(string.char(string.byte(raw, base + 28) or 0, string.byte(raw, base + 29) or 0, 0, 0), 1) -- uint16
                flags = (string.byte(raw, base + 28) or 0) + (string.byte(raw, base + 29) or 0) * 256
                local side   = string.byte(raw, base + 30) or 0
                local userId = string.byte(raw, base + 31) or 0
                tile_data.offMeshCons[i] = { pos = pos0, radius = radius or 0.0, flags = flags, side = side, userId = userId }
            end
        end
    end

    -- Links
    bytes_to_read = tile_data.maxLinkCount * LINK_SIZE
    if pos + bytes_to_read -1 > #data then return nil, "Data too short for links. Expected: " .. bytes_to_read .. ", Remaining: " .. (#data - pos + 1) end
    tile_data.links_raw = string.sub(data, pos, pos + bytes_to_read - 1)
    pos = pos + bytes_to_read
    -- Parse dtLink entries (subset)
    tile_data.links = {}
    do
        local raw = tile_data.links_raw
        for i = 1, tile_data.maxLinkCount do
            local base = (i - 1) * LINK_SIZE + 1
            if base + LINK_SIZE - 1 <= #raw then
                local ref = read_u32_val(raw, base)
                local dir = string.byte(raw, base + 4) or 0
                local side = string.byte(raw, base + 5) or 0
                local bmin = string.byte(raw, base + 6) or 0
                local bmax = string.byte(raw, base + 7) or 0
                local userId = read_u32_val(raw, base + 8)
                if ref ~= 0 then
                    tile_data.links[#tile_data.links + 1] = { id = i, ref = ref, dir = dir, side = side, bmin = bmin, bmax = bmax, userId = userId or 0 }
                end
            end
        end
    end

    local consumed = pos - 21
    if consumed ~= tile_data.dataSize then
        return nil, string.format("Size mismatch: consumed %d bytes, expected %d bytes (dataSize)", consumed, tile_data.dataSize)
    end

    return tile_data
end

function MMap.parse_tile_file(filename)
	local data = core.read_data_file(filename)
	if not data or data == "" then
		return nil, "Failed to read file: " .. tostring(filename)
	end
	return MMap.parse_tile(data)
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

-- Extract polygons and centers from parsed tile into game-space coordinates.
-- Accepts an optional toGameCoordinatesFn(nx, ny, nz) -> (gx, gy, gz).
function MMap.extract_polygons(tile_data, toGameCoordinatesFn)
    local polygons = {}
    if not tile_data or not tile_data.polys or tile_data.polyCount == 0 then
        return polygons
    end
    local toGame = toGameCoordinatesFn or function(nx, ny, nz) return nx, ny, nz end
    local verts = tile_data.vertices or {}
    local vertCount = tile_data.vertCount or 0
    for _, poly in ipairs(tile_data.polys or {}) do
        local poly_type = math.floor((poly.areaAndtype or 0) / 64) % 4
        if poly_type == 0 then
            local coords = {}
            local center = { x = 0, y = 0, z = 0 }
            local used = 0
            for j = 1, (poly.vertCount or 0) do
                local vertex_index = (poly.verts and poly.verts[j]) or 0
                local one_based = vertex_index + 1
                if one_based >= 1 and one_based <= vertCount then
                    local pos = (one_based - 1) * 3 + 1
                    if pos + 2 <= #verts then
                        local mx, my, mz = verts[pos], verts[pos + 1], verts[pos + 2]
                        local gx, gy, gz = toGame(mx, my, mz)
                        coords[#coords + 1] = { x = gx, y = gy, z = gz }
                        center.x = center.x + gx
                        center.y = center.y + gy
                        center.z = center.z + gz
                        used = used + 1
                    end
                end
            end
            if used >= 3 and #coords >= 3 then
                center.x = center.x / used
                center.y = center.y / used
                center.z = center.z / used
                polygons[#polygons + 1] = {
                    id = poly.id,
                    center = center,
                    vertices = {}, -- optional; not needed by consumers
                    coords = coords,
                    vertex_count = #coords,
                    flags = poly.flags,
                    areaAndtype = poly.areaAndtype,
                    neis = poly.neis,
                    tile = tile_data,
                    raw_verts = poly.verts,
                }
            end
        end
    end
    return polygons
end

-- Cached loader: returns parsed tile, polygons (for a given transform key), and timings
function MMap.get_tile_with_polygons(filename, toGameCoordinatesFn, transformKey)
    local key = transformKey or "default"
    local t_read0 = core.cpu_ticks and core.cpu_ticks() or 0
    local t_read1 = t_read0
    local t_parse0, t_parse1 = 0, 0
    local t_extract0, t_extract1 = 0, 0

    -- Parse/cache tile
    local parsed = parsed_tile_cache[filename]
    if parsed == nil then
        local data = core.read_data_file(filename)
        t_read1 = core.cpu_ticks and core.cpu_ticks() or t_read0
        if data and #data > 0 then
            t_parse0 = core.cpu_ticks and core.cpu_ticks() or 0
            parsed = MMap.parse_tile(data)
            t_parse1 = core.cpu_ticks and core.cpu_ticks() or t_parse0
            parsed_tile_cache[filename] = parsed or false
        else
            parsed_tile_cache[filename] = false
        end
    elseif parsed == false then
        return nil, nil, { read_ms = 0, parse_ms = 0, extract_ms = 0 }
    end

    if not parsed then
        return nil, nil, { read_ms = 0, parse_ms = 0, extract_ms = 0 }
    end

    -- Extract/cache polygons for this transform
    polygons_cache_by_transform[key] = polygons_cache_by_transform[key] or {}
    local poly_cache = polygons_cache_by_transform[key]
    local polys = poly_cache[filename]
    if polys == nil then
        t_extract0 = core.cpu_ticks and core.cpu_ticks() or 0
        polys = MMap.extract_polygons(parsed, toGameCoordinatesFn)
        t_extract1 = core.cpu_ticks and core.cpu_ticks() or t_extract0
        poly_cache[filename] = polys or false
    elseif polys == false then
        polys = nil
    end

    local hz = core.cpu_ticks_per_second and core.cpu_ticks_per_second() or 0
    local function ticks_to_ms(t0, t1)
        if not hz or hz <= 0 then return 0.0 end
        return ((t1 or 0) - (t0 or 0)) * 1000.0 / hz
    end
    local timings = {
        read_ms = ticks_to_ms(t_read0, t_read1),
        parse_ms = ticks_to_ms(t_parse0, t_parse1),
        extract_ms = ticks_to_ms(t_extract0, t_extract1),
    }
    return parsed, polys, timings
end

return MMap
