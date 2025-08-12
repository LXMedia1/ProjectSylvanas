local constants = require("gui/utils/constants")

local Separator = {}
Separator.__index = Separator

function Separator:new(owner_gui, x, y, w)
  local o = setmetatable({}, Separator)
  o.gui = owner_gui
  o.x = x or 0
  o.y = y or 0
  o.w = w or 200
  o.visible_if = nil
  return o
end

function Separator:set_visible_if(fn) self.visible_if = fn end
function Separator:is_visible() if self.visible_if then return not not self.visible_if(self) end return true end

function Separator:render()
  if not (self.gui and self.gui.is_open and self:is_visible()) then return end
  local gx = self.gui.x + self.x
  local gy = self.gui.y + self.y
  local w = self.w
  local c = constants.color.new(32,40,70,200)
  if core.graphics.rect_2d then
    core.graphics.rect_2d(constants.vec2.new(gx, gy), w, 1, c, 1, 0)
  end
end

return Separator


