local constants = require("gui/utils/constants")
local helpers = require("gui/utils/helpers")

local Toggle = {}
Toggle.__index = Toggle

function Toggle:new(owner_gui, x, y, w, h, checked, on_change)
  local o = setmetatable({}, Toggle)
  o.gui = owner_gui
  o.x, o.y = x or 0, y or 0
  o.w, o.h = w or 46, h or 22
  o.checked = not not checked
  o.on_change = on_change
  o.visible_if = nil
  return o
end

function Toggle:set_visible_if(fn) self.visible_if = fn end
function Toggle:is_visible() if self.visible_if then return not not self.visible_if(self) end return true end

function Toggle:render()
  if not (self.gui and self.gui.is_open and self:is_visible()) then return end
  local gx, gy = self.gui.x + self.x, self.gui.y + self.y
  local w, h = self.w, self.h
  local r = math.floor(h/2)
  local bg_off = constants.color.new(60,70,95,210)
  local bg_on  = constants.color.new(86, 140, 220, 230)
  local knob = constants.color.white(240)
  local bg = self.checked and bg_on or bg_off
  if core.graphics.rect_2d_filled then
    core.graphics.rect_2d_filled(constants.vec2.new(gx, gy), w, h, bg, r)
  end
  local kx = self.checked and (gx + w - h + 1) or (gx + 1)
  if core.graphics.rect_2d_filled then
    core.graphics.rect_2d_filled(constants.vec2.new(kx, gy + 1), h - 2, h - 2, knob, r - 2)
  end
  local m = constants.mouse_state.position
  if helpers.is_point_in_rect(m.x, m.y, gx, gy, w, h) and constants.mouse_state.left_clicked then
    self.checked = not self.checked
    if self.on_change then self.on_change(self, self.checked) end
  end
end

return Toggle


