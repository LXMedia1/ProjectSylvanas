local constants = require("gui/utils/constants")

local Checkbox = {}
Checkbox.__index = Checkbox

function Checkbox:new(owner_gui, label, x, y, checked, on_change)
    local o = setmetatable({}, Checkbox)
    o.gui = owner_gui
    o.label = tostring(label or "")
    o.x = tonumber(x or 0) or 0
    o.y = tonumber(y or 0) or 0
    o.size = 18
    o.checked = (checked and true) or false
    o.on_change = on_change
    o.enabled = true
    o.visible_if = nil
    return o
end

function Checkbox:set_on_change(cb)
    self.on_change = cb
end

function Checkbox:set_visible_if(fn)
    self.visible_if = fn
end

function Checkbox:is_visible()
    if self.visible_if then return not not self.visible_if(self) end
    return true
end

function Checkbox:get()
    return self.checked
end

function Checkbox:set(val)
    local new_val = not not val
    if new_val ~= self.checked then
        self.checked = new_val
        if self.on_change then self.on_change(self, self.checked) end
    end
end

function Checkbox:toggle()
    self:set(not self.checked)
end

function Checkbox:render()
    if not (self.gui and self.gui.is_open) then return end
    if not self:is_visible() then return end
    if not core.graphics then return end

    local gx = self.gui.x + self.x
    local gy = self.gui.y + self.y
    local s = self.size
    local mouse = constants.mouse_state.position
    local hovered = (mouse.x >= gx and mouse.x <= gx + s and mouse.y >= gy and mouse.y <= gy + s)

    local col_border = constants.color.new(18, 22, 30, 220)
    local col_bg = constants.color.new(30, 40, 60, 200)
    local col_bg_hover = constants.color.new(40, 60, 90, 220)
    local col_tick = constants.color.new(220, 235, 255, 255)

    local fill = hovered and col_bg_hover or col_bg
    if core.graphics.rect_2d_filled then
        core.graphics.rect_2d_filled(constants.vec2.new(gx, gy), s, s, fill, 4)
    end
    if core.graphics.rect_2d then
        core.graphics.rect_2d(constants.vec2.new(gx, gy), s, s, col_border, 1, 4)
    end

    if self.checked and core.graphics.line_2d then
        local lw = 2
        local x1, y1 = gx + 4, gy + math.floor(s/2)
        local x2, y2 = gx + math.floor(s/2) - 1, gy + s - 5
        local x3, y3 = gx + s - 4, gy + 4
        core.graphics.line_2d(constants.vec2.new(x1, y1), constants.vec2.new(x2, y2), col_tick, lw)
        core.graphics.line_2d(constants.vec2.new(x2, y2), constants.vec2.new(x3, y3), col_tick, lw)
    end

    if self.label ~= "" and core.graphics.text_2d then
        local tx = gx + s + 8
        local ty = gy + math.floor((s - constants.FONT_SIZE) / 2) - 1
        core.graphics.text_2d(self.label, constants.vec2.new(tx, ty), constants.FONT_SIZE, constants.color.white(255), false)
    end

    if hovered and constants.mouse_state.left_clicked then
        self:toggle()
    end
end

return Checkbox


