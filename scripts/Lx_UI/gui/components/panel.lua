local constants = require("gui/utils/constants")

local Panel = {}
Panel.__index = Panel

function Panel:new(owner_gui, title, x, y, w, h)
    local o = setmetatable({}, Panel)
    o.gui = owner_gui
    o.title = tostring(title or "Panel")
    o.x = tonumber(x or 0) or 0
    o.y = tonumber(y or 0) or 0
    o.w = tonumber(w or 200) or 200
    o.h = tonumber(h or 120) or 120
    o.header_h = 20
    o.padding = 8
    o.visible_if = nil
    return o
end

function Panel:set_visible_if(fn)
    self.visible_if = fn
end

function Panel:is_visible()
    if self.visible_if then return not not self.visible_if(self) end
    return true
end

function Panel:get_content_origin()
    -- Return coordinates RELATIVE to the owner GUI, so child components can use them directly
    local cx = self.x + self.padding
    local cy = self.y + self.header_h + self.padding
    return cx, cy
end

function Panel:get_content_size()
    local cw = self.w - self.padding * 2
    local ch = self.h - self.header_h - self.padding * 2
    if cw < 0 then cw = 0 end
    if ch < 0 then ch = 0 end
    return cw, ch
end

function Panel:render()
    if not (self.gui and self.gui.is_open and self:is_visible()) then return end
    if not core.graphics then return end

    local gx = self.gui.x + self.x
    local gy = self.gui.y + self.y

    local col_bg = constants.color.new(18, 24, 40, 160)
    local col_border = constants.color.new(18, 22, 30, 220)
    local col_header = constants.color.new(44, 64, 110, 210)
    local col_title = constants.color.white(255)

    if core.graphics.rect_2d_filled then
        core.graphics.rect_2d_filled(constants.vec2.new(gx, gy), self.w, self.h, col_bg, 6)
        core.graphics.rect_2d_filled(constants.vec2.new(gx, gy), self.w, self.header_h, col_header, 6)
    end
    if core.graphics.rect_2d then
        core.graphics.rect_2d(constants.vec2.new(gx, gy), self.w, self.h, col_border, 1, 6)
        core.graphics.rect_2d(constants.vec2.new(gx, gy + self.header_h), self.w, 1, col_border, 1, 0)
    end
    if self.title ~= "" and core.graphics.text_2d then
        local tx = gx + 8
        local ty = gy + math.floor((self.header_h - constants.FONT_SIZE) / 2) - 1
        core.graphics.text_2d(self.title, constants.vec2.new(tx, ty), constants.FONT_SIZE, col_title, false)
    end
end

return Panel


