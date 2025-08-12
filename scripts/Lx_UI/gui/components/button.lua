local constants = require("gui/utils/constants")

local Button = {}
Button.__index = Button

function Button:new(owner_gui, text, x, y, w, h, on_click)
    local o = setmetatable({}, Button)
    o.gui = owner_gui
    o.text = tostring(text or "Button")
    o.x = tonumber(x or 0) or 0
    o.y = tonumber(y or 0) or 0
    o.w = tonumber(w or 100) or 100
    o.h = tonumber(h or 24) or 24
    o.on_click = on_click
    o.enabled = true
    o._pressed_in = false
    return o
end

function Button:set_on_click(cb)
    self.on_click = cb
end

function Button:render()
    if not (self.gui and self.gui.is_open) then return end
    if not core.graphics then return end

    local gx = self.gui.x + self.x
    local gy = self.gui.y + self.y
    local gw = self.w
    local gh = self.h

    local mouse = constants.mouse_state.position
    local hovered = (mouse.x >= gx and mouse.x <= gx + gw and mouse.y >= gy and mouse.y <= gy + gh)

    local col_border = constants.color.new(18, 22, 30, 220)
    local col_bg = constants.color.new(50, 78, 130, 220)
    local col_hover = constants.color.new(70, 110, 190, 240)
    local col_active = constants.color.new(92, 128, 205, 255)
    local fill = hovered and col_hover or col_bg
    if constants.mouse_state.left_down and hovered then fill = col_active end

    if core.graphics.rect_2d_filled then
        core.graphics.rect_2d_filled(constants.vec2.new(gx, gy), gw, gh, fill, 6)
    end
    if core.graphics.rect_2d then
        core.graphics.rect_2d(constants.vec2.new(gx, gy), gw, gh, col_border, 1, 6)
    end

    if core.graphics.text_2d then
        local fs = (constants.Theme and constants.Theme.font and constants.Theme.font.button) or constants.FONT_SIZE
        local tw = (core.graphics.get_text_width and core.graphics.get_text_width(self.text, fs, 0)) or 0
        local tx = gx + math.floor((gw - tw) / 2)
        local ty = gy + math.floor((gh - fs) / 2) - 1
        core.graphics.text_2d(self.text, constants.vec2.new(tx, ty), fs, constants.color.white(245), false)
    end

    if hovered and constants.mouse_state.left_clicked then self._pressed_in = true end
    if self._pressed_in and not constants.mouse_state.left_down then
        self._pressed_in = false
        if hovered and self.on_click then self.on_click(self) end
    end
end

return Button


