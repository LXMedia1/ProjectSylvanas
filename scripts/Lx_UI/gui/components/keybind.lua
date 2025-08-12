local constants = require("gui/utils/constants")
local helpers = require("gui/utils/helpers")

local Keybind = {}
Keybind.__index = Keybind

function Keybind:new(owner_gui, x, y, w, h, label, on_change)
  local o = setmetatable({}, Keybind)
  o.gui = owner_gui
  o.x = tonumber(x or 0) or 0
  o.y = tonumber(y or 0) or 0
  o.w = tonumber(w or 160) or 160
  o.h = tonumber(h or 22) or 22
  o.label = tostring(label or "")
  o.key_code = nil
  o.is_listening = false
  o.on_change = on_change
  o.visible_if = nil
  o._keys_down = {}
  return o
end

function Keybind:set_visible_if(fn)
  self.visible_if = fn
end

function Keybind:is_visible()
  if self.visible_if then return not not self.visible_if(self) end
  return true
end

local function key_edge(self, vk)
  if not core.input or not core.input.is_key_pressed then return false end
  local down = core.input.is_key_pressed(vk)
  local prev = self._keys_down[vk] or false
  self._keys_down[vk] = down
  return down and not prev
end

local function vk_to_text(vk)
  if core.graphics and core.graphics.translate_vkey_to_string then
    local s = core.graphics.translate_vkey_to_string(vk)
    if s and s ~= "" then return s end
  end
  return tostring(vk)
end

function Keybind:render()
  if not (self.gui and self.gui.is_open and self:is_visible()) then return end
  local gx = self.gui.x + self.x
  local gy = self.gui.y + self.y
  local w, h = self.w, self.h

  -- background
  local col_bg = constants.color.new(20, 26, 42, 245)
  local col_bd = constants.color.new(32, 40, 70, 255)
  if core.graphics.rect_2d_filled then
    core.graphics.rect_2d_filled(constants.vec2.new(gx, gy), w, h, col_bg, 4)
  end
  if core.graphics.rect_2d then
    core.graphics.rect_2d(constants.vec2.new(gx, gy), w, h, col_bd, 1, 4)
  end

  -- label text
  local text = self.is_listening and "Press key..." or (self.label ~= "" and (self.label .. ": ") or "")
  local val = self.key_code and vk_to_text(self.key_code) or "None"
  local disp = text .. val
  if core.graphics.text_2d then
    core.graphics.text_2d(disp, constants.vec2.new(gx + 8, gy - 1), constants.FONT_SIZE, constants.color.white(255), false)
  end

  -- click to toggle listening
  local m = constants.mouse_state.position
  local over = helpers.is_point_in_rect(m.x, m.y, gx, gy, w, h)
  if over and constants.mouse_state.left_clicked then
    self.is_listening = true
  elseif constants.mouse_state.left_clicked and not over then
    self.is_listening = false
  end

  -- capture key while listening
  if self.is_listening then
    -- Scan a conservative VK range
    for vk = 0x01, 0xFE do
      if key_edge(self, vk) then
        self.key_code = vk
        self.is_listening = false
        if self.on_change then self.on_change(self, vk, vk_to_text(vk)) end
        break
      end
    end
  end
end

return Keybind



