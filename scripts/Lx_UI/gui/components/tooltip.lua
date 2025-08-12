local constants = require("gui/utils/constants")

local Tooltip = {}
Tooltip.__index = Tooltip

function Tooltip:new()
  local o = setmetatable({}, Tooltip)
  o.text = nil
  o._show_at_ms = 0
  o.delay_ms = 350
  o.visible = false
  return o
end

function Tooltip:show(text)
  self.text = text
  self._show_at_ms = (core.time and core.time()) or 0
  self.visible = true
end

function Tooltip:hide()
  self.visible = false
  self.text = nil
end

function Tooltip:render_follow_mouse()
  if not self.visible or not self.text or self.text == "" then return end
  local now = (core.time and core.time()) or 0
  if now - (self._show_at_ms or now) < self.delay_ms then return end
  if not core.graphics or not core.graphics.text_2d then return end

  local mouse = constants.mouse_state.position
  local pad = 6
  local tw = (core.graphics.get_text_width and core.graphics.get_text_width(self.text, constants.FONT_SIZE, 0)) or 80
  local w = tw + pad * 2
  local h = (constants.FONT_SIZE or 14) + 6
  local x = mouse.x + 14
  local y = mouse.y + 18

  if core.graphics.get_screen_size then
    local s = core.graphics.get_screen_size()
    if x + w > s.x - 4 then x = s.x - 4 - w end
    if y + h > s.y - 4 then y = mouse.y - 20 - h end
  end

  local bg = constants.color.new(22, 28, 44, 235)
  local bd = constants.color.new(32, 40, 70, 255)
  core.graphics.rect_2d_filled(constants.vec2.new(x, y), w, h, bg, 4)
  core.graphics.rect_2d(constants.vec2.new(x, y), w, h, bd, 1, 4)
  core.graphics.text_2d(self.text, constants.vec2.new(x + pad, y + 2), constants.FONT_SIZE, constants.color.white(255), false)
end

return Tooltip


