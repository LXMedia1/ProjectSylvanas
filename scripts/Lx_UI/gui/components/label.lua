local constants = require("gui/utils/constants")

local Label = {}
Label.__index = Label

-- Constructor
function Label:new(owner_gui, text, x, y, col, font_size)
    local o = setmetatable({}, Label)
    o.gui = owner_gui
    o.text = tostring(text or "")
    o.x = tonumber(x or 0) or 0
    o.y = tonumber(y or 0) or 0
    o.color = col or constants.color.white(255)
    local theme_size = (constants.Theme and constants.Theme.font and constants.Theme.font.label) or constants.FONT_SIZE
    o.size = font_size or theme_size
    o.visible_if = nil
    return o
end

function Label:set_visible_if(fn)
    self.visible_if = fn
end

function Label:is_visible()
    if self.visible_if then return not not self.visible_if(self) end
    return true
end

function Label:render()
    if not (self.gui and self.gui.is_open) then return end
    if not self:is_visible() then return end
    if not (core.graphics and core.graphics.text_2d) then return end
    core.graphics.text_2d(self.text, constants.vec2.new(self.gui.x + self.x, self.gui.y + self.y), self.size, self.color, false)
end

return Label


