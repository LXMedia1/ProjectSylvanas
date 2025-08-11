local constants = require("gui/utils/constants")
local helpers = require("gui/utils/helpers")

local Slider = {}
Slider.__index = Slider

-- opts: { vertical = false, is_float = false, decimals = 2, thickness = 10 }
function Slider:new(owner_gui, x, y, length, min_value, max_value, value, on_change, opts)
    local o = setmetatable({}, Slider)
    o.gui = owner_gui
    o.x = tonumber(x or 0) or 0
    o.y = tonumber(y or 0) or 0
    o.length = tonumber(length or 160) or 160
    o.min_value = tonumber(min_value or 0) or 0
    o.max_value = tonumber(max_value or 100) or 100
    o.value = tonumber(value or o.min_value) or o.min_value
    if o.max_value == o.min_value then o.max_value = o.min_value + 1 end
    o.on_change = on_change

    o.vertical = (opts and opts.vertical) and true or false
    o.is_float = (opts and opts.is_float) and true or false
    o.decimals = (opts and opts.decimals) or 2
    o.thickness = (opts and opts.thickness) or 12
    o.visible_if = nil
    o.dragging = false
    return o
end

function Slider:set_visible_if(fn)
    self.visible_if = fn
end

function Slider:is_visible()
    if self.visible_if then return not not self.visible_if(self) end
    return true
end

function Slider:get_value()
    return self.value
end

function Slider:set_value(v, fire)
    local nv = tonumber(v)
    if not nv then return end
    if nv < self.min_value then nv = self.min_value end
    if nv > self.max_value then nv = self.max_value end
    if not self.is_float then nv = math.floor(nv + 0.5) end
    if nv ~= self.value then
        self.value = nv
        if fire and self.on_change then self.on_change(self, self.value) end
    end
end

local function lerp(a, b, t) return a + (b - a) * t end

function Slider:render()
    if not (self.gui and self.gui.is_open and self:is_visible()) then return end
    if not core.graphics then return end

    local gx = self.gui.x + self.x
    local gy = self.gui.y + self.y
    local len = self.length
    local th = self.thickness

    local col_track = constants.color.new(18, 24, 40, 220)
    local col_border = constants.color.new(18, 22, 30, 220)
    local col_fill = constants.color.new(86, 120, 200, 240)
    local col_knob = constants.color.white(255)

    -- compute fraction
    local f = (self.value - self.min_value) / (self.max_value - self.min_value)
    if f < 0 then f = 0 elseif f > 1 then f = 1 end

    -- geometry
    if not self.vertical then
        -- horizontal
        local w, h = len, th
        if core.graphics.rect_2d_filled then
            core.graphics.rect_2d_filled(constants.vec2.new(gx, gy), w, h, col_track, 4)
        end
        if core.graphics.rect_2d then
            core.graphics.rect_2d(constants.vec2.new(gx, gy), w, h, col_border, 1, 4)
        end
        -- fill
        if core.graphics.rect_2d_filled then
            core.graphics.rect_2d_filled(constants.vec2.new(gx, gy), math.floor(w * f), h, col_fill, 4)
        end
        -- knob
        local kx = gx + math.floor(w * f) - 6
        local ky = gy - 2
        if core.graphics.rect_2d_filled then
            core.graphics.rect_2d_filled(constants.vec2.new(kx, ky), 12, h + 4, col_knob, 3)
        end
        -- input handling
        local m = constants.mouse_state.position
        local over = helpers.is_point_in_rect(m.x, m.y, gx, gy - 4, w, h + 8)
        if over and constants.mouse_state.left_down and not self.dragging then
            self.dragging = true
        end
        if self.dragging then
            if constants.mouse_state.left_down then
                local t = (m.x - gx) / w
                if t < 0 then t = 0 elseif t > 1 then t = 1 end
                local nv = lerp(self.min_value, self.max_value, t)
                if not self.is_float then nv = math.floor(nv + 0.5) else
                    local p = 10 ^ (self.decimals or 2)
                    nv = math.floor(nv * p + 0.5) / p
                end
                if nv ~= self.value then
                    self.value = nv
                    if self.on_change then self.on_change(self, self.value) end
                end
            else
                self.dragging = false
            end
        end
    else
        -- vertical
        local w, h = th, len
        if core.graphics.rect_2d_filled then
            core.graphics.rect_2d_filled(constants.vec2.new(gx, gy), w, h, col_track, 4)
        end
        if core.graphics.rect_2d then
            core.graphics.rect_2d(constants.vec2.new(gx, gy), w, h, col_border, 1, 4)
        end
        -- fill from bottom up
        if core.graphics.rect_2d_filled then
            local fh = math.floor(h * f)
            core.graphics.rect_2d_filled(constants.vec2.new(gx, gy + h - fh), w, fh, col_fill, 4)
        end
        -- knob
        local ky = gy + h - math.floor(h * f) - 6
        local kx = gx - 2
        if core.graphics.rect_2d_filled then
            core.graphics.rect_2d_filled(constants.vec2.new(kx, ky), w + 4, 12, col_knob, 3)
        end
        -- input handling
        local m = constants.mouse_state.position
        local over = helpers.is_point_in_rect(m.x, m.y, gx - 4, gy, w + 8, h)
        if over and constants.mouse_state.left_down and not self.dragging then
            self.dragging = true
        end
        if self.dragging then
            if constants.mouse_state.left_down then
                local t = (gy + h - m.y) / h
                if t < 0 then t = 0 elseif t > 1 then t = 1 end
                local nv = lerp(self.min_value, self.max_value, t)
                if not self.is_float then nv = math.floor(nv + 0.5) else
                    local p = 10 ^ (self.decimals or 2)
                    nv = math.floor(nv * p + 0.5) / p
                end
                if nv ~= self.value then
                    self.value = nv
                    if self.on_change then self.on_change(self, self.value) end
                end
            else
                self.dragging = false
            end
        end
    end
end

return Slider


