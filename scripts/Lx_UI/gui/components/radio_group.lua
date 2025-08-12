local constants = require("gui/utils/constants")
local helpers = require("gui/utils/helpers")

local RadioGroup = {}
RadioGroup.__index = RadioGroup

-- items: { "Option A", "Option B", ... }
function RadioGroup:new(owner_gui, x, y, items, selected_index, on_change)
  local o = setmetatable({}, RadioGroup)
  o.gui = owner_gui
  o.x, o.y = x or 0, y or 0
  o.items = items or {}
  o.selected = tonumber(selected_index or 1) or 1
  o.on_change = on_change
  o.visible_if = nil
  return o
end

function RadioGroup:set_visible_if(fn) self.visible_if = fn end
function RadioGroup:is_visible() if self.visible_if then return not not self.visible_if(self) end return true end

function RadioGroup:render()
  if not (self.gui and self.gui.is_open and self:is_visible()) then return end
  local gx, gy = self.gui.x + self.x, self.gui.y + self.y
  local theme_fs = (constants.Theme and constants.Theme.font and constants.Theme.font.checkbox) or (constants.FONT_SIZE or 14)
  local base_fs = math.max(13, theme_fs)
  local row_h = base_fs + 6
  for i = 1, #self.items do
    local label = tostring(self.items[i] or ("Item " .. tostring(i)))
    local y = gy + (i - 1) * row_h
    -- radio circle
    local cx, cy = gx + 9, y + math.floor(row_h / 2)
    if core.graphics.rect_2d_filled then
      core.graphics.rect_2d_filled(constants.vec2.new(cx - 6, cy - 6), 12, 12, constants.color.new(30, 46, 80, 220), 6)
    end
    if core.graphics.rect_2d then
      core.graphics.rect_2d(constants.vec2.new(cx - 6, cy - 6), 12, 12, constants.color.new(18, 22, 30, 240), 1, 6)
    end
    if i == self.selected and core.graphics.rect_2d_filled then
      core.graphics.rect_2d_filled(constants.vec2.new(cx - 3, cy - 3), 6, 6, constants.color.new(255, 255, 255, 255), 3)
    end
    -- label
    if core.graphics.text_2d then
      core.graphics.text_2d(label, constants.vec2.new(gx + 20, y - 1), base_fs, constants.color.white(255), false)
    end
    -- input
    local m = constants.mouse_state.position
    if helpers.is_point_in_rect(m.x, m.y, gx, y, 160, row_h) and constants.mouse_state.left_clicked then
      if self.selected ~= i then
        self.selected = i
        if self.on_change then self.on_change(self, i, label) end
      end
    end
  end
end

return RadioGroup


