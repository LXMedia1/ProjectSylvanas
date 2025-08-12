local constants = require("gui/utils/constants")

local ProgressBar = {}
ProgressBar.__index = ProgressBar

function ProgressBar:new(owner_gui, x, y, w, h, value)
  local o = setmetatable({}, ProgressBar)
  o.gui = owner_gui
  o.x, o.y = x or 0, y or 0
  o.w, o.h = w or 160, h or 14
  o.value = tonumber(value or 0) or 0 -- 0..1
  o.visible_if = nil
  return o
end

function ProgressBar:set_visible_if(fn) self.visible_if = fn end
function ProgressBar:is_visible() if self.visible_if then return not not self.visible_if(self) end return true end
function ProgressBar:set_value(v)
  v = tonumber(v) or 0
  if v < 0 then v = 0 elseif v > 1 then v = 1 end
  self.value = v
end

function ProgressBar:render()
  if not (self.gui and self.gui.is_open and self:is_visible()) then return end
  local gx, gy = self.gui.x + self.x, self.gui.y + self.y
  local w, h = self.w, self.h
  local bg = constants.color.new(16, 20, 34, 235)
  local bd = constants.color.new(32, 40, 70, 255)
  local fill = constants.color.new(120, 160, 230, 255)
  core.graphics.rect_2d_filled(constants.vec2.new(gx, gy), w, h, bg, 4)
  core.graphics.rect_2d(constants.vec2.new(gx, gy), w, h, bd, 1, 4)
  local fw = math.floor(w * (self.value or 0))
  if fw > 0 then
    core.graphics.rect_2d_filled(constants.vec2.new(gx, gy), fw, h, fill, 4)
  end
end

return ProgressBar


