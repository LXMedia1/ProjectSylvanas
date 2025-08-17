-- Binary Data Reader Utilities

local BinaryReader = {}
BinaryReader.__index = BinaryReader

function BinaryReader:new(data)
    local obj = {
        data = data,
        pos = 1,
        size = #data
    }
    setmetatable(obj, self)
    return obj
end

function BinaryReader:remaining()
    return self.size - self.pos + 1
end

function BinaryReader:eof()
    return self.pos > self.size
end

function BinaryReader:seek(position)
    self.pos = math.max(1, math.min(position, self.size + 1))
end

function BinaryReader:skip(bytes)
    self.pos = self.pos + bytes
end

-- Read unsigned 8-bit integer
function BinaryReader:read_u8()
    if self.pos > self.size then return nil end
    local byte = string.byte(self.data, self.pos)
    self.pos = self.pos + 1
    return byte
end

-- Read unsigned 16-bit integer (little-endian)
function BinaryReader:read_u16()
    if self.pos + 1 > self.size then return nil end
    local b1 = string.byte(self.data, self.pos)
    local b2 = string.byte(self.data, self.pos + 1)
    self.pos = self.pos + 2
    return b1 + (b2 * 256)
end

-- Read unsigned 32-bit integer (little-endian)
function BinaryReader:read_u32()
    if self.pos + 3 > self.size then return nil end
    local b1 = string.byte(self.data, self.pos)
    local b2 = string.byte(self.data, self.pos + 1)
    local b3 = string.byte(self.data, self.pos + 2)
    local b4 = string.byte(self.data, self.pos + 3)
    self.pos = self.pos + 4
    return b1 + (b2 * 256) + (b3 * 65536) + (b4 * 16777216)
end

-- Read 32-bit float (little-endian)
function BinaryReader:read_f32()
    if self.pos + 3 > self.size then return nil end
    
    local b1 = string.byte(self.data, self.pos)
    local b2 = string.byte(self.data, self.pos + 1)
    local b3 = string.byte(self.data, self.pos + 2)
    local b4 = string.byte(self.data, self.pos + 3)
    self.pos = self.pos + 4
    
    local sign = (b4 >= 128) and -1 or 1
    local exp = ((b4 % 128) * 2) + math.floor(b3 / 128)
    local mantissa = ((b3 % 128) * 65536) + (b2 * 256) + b1
    
    if exp == 0 then
        return sign * mantissa * (2 ^ -149)
    elseif exp == 255 then
        return (mantissa == 0) and (sign * math.huge) or 0/0
    else
        return sign * (1 + mantissa / 8388608) * (2 ^ (exp - 127))
    end
end

-- Read array of floats
function BinaryReader:read_f32_array(count)
    local result = {}
    for i = 1, count do
        local val = self:read_f32()
        if val == nil then return nil end
        result[i] = val
    end
    return result
end

-- Read array of unsigned 8-bit integers
function BinaryReader:read_u8_array(count)
    local result = {}
    for i = 1, count do
        local val = self:read_u8()
        if val == nil then return nil end
        result[i] = val
    end
    return result
end

-- Read array of unsigned 16-bit integers
function BinaryReader:read_u16_array(count)
    local result = {}
    for i = 1, count do
        local val = self:read_u16()
        if val == nil then return nil end
        result[i] = val
    end
    return result
end

-- Read raw bytes
function BinaryReader:read_bytes(count)
    if self.pos + count - 1 > self.size then return nil end
    local bytes = string.sub(self.data, self.pos, self.pos + count - 1)
    self.pos = self.pos + count
    return bytes
end

return BinaryReader