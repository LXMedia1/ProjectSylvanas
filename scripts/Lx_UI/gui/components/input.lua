local constants = require("gui/utils/constants")
local helpers = require("gui/utils/helpers")

local Input = {}
Input.__index = Input

function Input:new(owner_gui, x, y, w, h, opts, on_change)
  local o = setmetatable({}, Input)
  o.gui = owner_gui
  o.x = tonumber(x or 0) or 0
  o.y = tonumber(y or 0) or 0
  o.w = tonumber(w or 180) or 180
  o.h = tonumber(h or 22) or 22
  o.text = tostring((opts and opts.text) or "")
  o.multiline = not not (opts and opts.multiline)
  o.on_change = on_change
  o.visible_if = nil
  o.is_focused = false
  o._keys_down = {}
  o._caret_t = 0
  -- invisible blocker window to stop click-through and help block game input while editing
  if core.menu and core.menu.window then
    local bid = "lx_ui_input_blocker_" .. tostring(owner_gui.unique_key or "gui") .. "_" .. tostring(math.random(1000000))
    o._blocker = core.menu.window(bid)
  end
  o._movement_locked = false
  -- invisible core text_input to capture keyboard focus
  o._proxy_id = "lxui_input_text_" .. tostring(owner_gui.unique_key or "gui") .. "_" .. tostring(math.random(1000000))
  if core.menu and core.menu.text_input then
    o._menu_text = core.menu.text_input(o._proxy_id, false)
  end
  return o
end

function Input:set_visible_if(fn)
  self.visible_if = fn
  return self
end

function Input:is_visible()
  if self.visible_if then return not not self.visible_if(self) end
  return true
end

function Input:set_multiline(v)
  self.multiline = not not v
end

function Input:get_text()
  return self.text
end

function Input:set_text(t)
  self.text = tostring(t or "")
end

local function draw_text_lines(text, x, y, w)
  -- naive rendering: split by \n only (no wrapping)
  local lines = {}
  for line in string.gmatch(text or "", "[^\n]*") do table.insert(lines, line) end
  for i = 1, #lines do
    local ty = y + (i - 1) * (constants.FONT_SIZE + 2)
    core.graphics.text_2d(lines[i], constants.vec2.new(x, ty), constants.FONT_SIZE, constants.color.white(255), false)
  end
end

local function key_edge(self, vk)
  local down = core.input and core.input.is_key_pressed and core.input.is_key_pressed(vk)
  local prev = self._keys_down[vk] or false
  self._keys_down[vk] = down
  return down and not prev
end

function Input:render()
  if not (self.gui and self.gui.is_open and self:is_visible()) then return end
  local gx = self.gui.x + self.x
  local gy = self.gui.y + self.y
  local w, h = self.w, self.h

  -- background and border
  local col_bg = constants.color.new(20, 26, 42, 245)
  local col_bd = constants.color.new(32, 40, 70, 255)
  if core.graphics.rect_2d_filled then
    core.graphics.rect_2d_filled(constants.vec2.new(gx, gy), w, h, col_bg, 4)
  end
  if core.graphics.rect_2d then
    core.graphics.rect_2d(constants.vec2.new(gx, gy), w, h, col_bd, 1, 4)
  end

  -- focus handling
  local m = constants.mouse_state.position
  local over = helpers.is_point_in_rect(m.x, m.y, gx, gy, w, h)
  if over and constants.mouse_state.left_clicked then
    -- focus this input, blur others
    self.is_focused = true
    if self.gui._text_inputs then
      for _, ti in ipairs(self.gui._text_inputs) do
        if ti ~= self then ti.is_focused = false end
      end
    end
  elseif constants.mouse_state.left_clicked and not over then
    self.is_focused = false
  end

  -- input handling when focused
  if self.is_focused and core.input and core.graphics and core.graphics.translate_vkey_to_string then
    if not self._movement_locked and core.input.disable_movement then
      core.input.disable_movement(true)
      self._movement_locked = true
    end
    -- Enter handling
    local VK_RETURN = 0x0D
    if key_edge(self, VK_RETURN) then
      if self.multiline then
        self.text = self.text .. "\n"
        if self.on_change then self.on_change(self, self.text) end
      else
        self.is_focused = false
      end
    end
    -- Backspace
    local VK_BACK = 0x08
    if key_edge(self, VK_BACK) then
      local len = string.len(self.text or "")
      if len > 0 then
        self.text = string.sub(self.text, 1, len - 1)
        if self.on_change then self.on_change(self, self.text) end
      end
    end
    -- basic character input: scan keys 0x20..0x5A
    for vk = 0x20, 0x5A do
      if vk ~= VK_RETURN and vk ~= VK_BACK then
        if key_edge(self, vk) then
          local ch = core.graphics.translate_vkey_to_string(vk)
          if ch and ch ~= "" then
            self.text = (self.text or "") .. ch
            if self.on_change then self.on_change(self, self.text) end
          end
        end
      end
    end
  end

  -- render text
  local pad = 6
  draw_text_lines(self.text or "", gx + pad, gy + math.floor((h - constants.FONT_SIZE) / 2) - 1, w - pad * 2)

  -- caret (blink)
  if self.is_focused then
    self._caret_t = (self._caret_t or 0) + 1
    if (self._caret_t % 60) < 30 then
      local tw = (core.graphics.get_text_width and core.graphics.get_text_width(self.text or "", constants.FONT_SIZE, 0)) or 0
      local cx = gx + pad + tw + 1
      local cy = gy + 4
      core.graphics.line_2d(constants.vec2.new(cx, cy), constants.vec2.new(cx, gy + h - 4), constants.color.white(230), 1)
    end
  else
    self._caret_t = 0
  end
end

-- Render an invisible menu window exactly over the input to block clicks
function Input:render_blocker()
  -- If not focused or not visible/open, ensure movement is unlocked and do nothing
  if (not self.is_focused) or (not (self.gui and self.gui.is_open)) or (self.visible_if and not self:is_visible()) then
    if self._movement_locked and core.input and core.input.disable_movement then
      core.input.disable_movement(false)
      self._movement_locked = false
    end
    return
  end
  if not self._blocker then return end
  local bx = self.gui.x + self.x
  local by = self.gui.y + self.y
  if self._blocker.stop_forcing_size then self._blocker:stop_forcing_size() end
  if self._blocker.force_next_begin_window_pos then
    self._blocker:force_next_begin_window_pos(constants.vec2.new(bx, by))
  end
  if self._blocker.set_next_window_min_size then
    self._blocker:set_next_window_min_size(constants.vec2.new(self.w, self.h))
  end
  if self._blocker.force_window_size then
    self._blocker:force_window_size(constants.vec2.new(self.w, self.h))
  end
  if self._blocker.set_background_multicolored then
    local c = constants.color.new(0,0,0,0)
    self._blocker:set_background_multicolored(c,c,c,c)
  end
  if self._blocker.begin then
    self._blocker:begin(
      0,
      false,
      constants.color.new(0,0,0,0),
      constants.color.new(0,0,0,0),
      0,
      (core.enums and core.enums.window_enums and core.enums.window_enums.window_behaviour_flags and core.enums.window_enums.window_behaviour_flags.NO_MOVE) or 0,
      0,
      0,
      function()
        if self._blocker.add_artificial_item_bounds then
          self._blocker:add_artificial_item_bounds(constants.vec2.new(0,0), constants.vec2.new(self.w, self.h))
        end
        -- render a hidden text_input to grab keyboard focus
        if self._menu_text and self._menu_text.render then
          self._menu_text:render("", "")
        end
      end
    )
  end
end

return Input


