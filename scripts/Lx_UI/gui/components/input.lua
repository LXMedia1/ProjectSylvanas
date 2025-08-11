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
  o._last_click_t = 0
  o._last_click_x = 0
  o._last_click_y = 0
  -- text editing state
  o._caret = string.len(o.text or "")
  o._sel_anchor = nil
  o._is_selecting = false
  o._mouse_was_down = false
  -- backspace repeat state (ms)
  o._bs_prev_down = false
  o._bs_next_repeat = 0
  o._force_focus_frames = 0
  o._pre_focus_active = false
  o._pre_focus_deadline_ms = 0
  -- small invisible menu window behind the input + a core text_input to grab focus
  if core.menu and core.menu.window then
    local bid = "lx_ui_input_blocker_" .. tostring(owner_gui.unique_key or "gui") .. "_" .. tostring(math.random(1000000))
    o._blocker = core.menu.window(bid)
  end
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

local function clamp(v, lo, hi)
  if v < lo then return lo elseif v > hi then return hi else return v end
end

local function measure(text)
  if core.graphics and core.graphics.get_text_width then
    return core.graphics.get_text_width(text or "", constants.FONT_SIZE, 0) or 0
  end
  return 0
end

local function split_lines_with_index(text)
  local lines, starts = {}, {}
  local idx = 1
  for line in string.gmatch(text or "", "[^\n]*") do
    table.insert(lines, line)
    table.insert(starts, idx)
    idx = idx + #line + 1 -- +1 for newline
  end
  return lines, starts
end

local function index_from_mouse(text, x_rel, y_rel)
  local line_h = constants.FONT_SIZE + 2
  local lines, starts = split_lines_with_index(text)
  local line_idx = clamp(1 + math.floor(y_rel / line_h), 1, #lines > 0 and #lines or 1)
  local line_text = lines[line_idx] or ""
  local line_start = starts[line_idx] or 1
  -- find nearest char by scanning widths (acceptable for short inputs)
  local best_i = 0
  local best_dx = 1e9
  for i = 0, #line_text do
    local px = measure(string.sub(line_text, 1, i))
    local dx = math.abs(px - x_rel)
    if dx < best_dx then
      best_dx = dx
      best_i = i
    end
  end
  return line_start - 1 + best_i
end

local function caret_pos_from_index(text, caret_index)
  local lines, starts = split_lines_with_index(text)
  local line_h = constants.FONT_SIZE + 2
  local lx, ly = 0, 0
  local idx = caret_index or 0
  for i = 1, #lines do
    local s = starts[i]
    local e = s + #lines[i] -- exclusive of newline
    if idx <= (e - 1) then
      lx = measure(string.sub(lines[i], 1, idx - s + 1))
      ly = (i - 1) * line_h
      return lx, ly
    end
  end
  -- fallthrough -> end of text
  local last_line = #lines > 0 and #lines or 1
  lx = measure(lines[last_line] or "")
  ly = (last_line - 1) * line_h
  return lx, ly
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
  -- cancel pre-focus after timeout
  do
    local now_t = (core.time and core.time()) or 0
    if self._pre_focus_active and now_t > (self._pre_focus_deadline_ms or 0) then
      self._pre_focus_active = false
      if not self.is_focused then constants.typing_capture = nil end
    end
  end
  if over and constants.mouse_state.left_clicked then
    -- focus only on a real double-click (short interval + minimal movement)
    local now_t = (core.time and core.time()) or 0
    local dt = now_t - (self._last_click_t or 0)
    local dx = (constants.mouse_state.position.x or 0) - (self._last_click_x or 0)
    local dy = (constants.mouse_state.position.y or 0) - (self._last_click_y or 0)
    local dist2 = dx*dx + dy*dy
    if dt >= 0 and dt <= 250 and dist2 <= 36 then
      self.is_focused = true
      constants.is_typing = true
      -- publish capture rect so menu can align hidden text_input reliably
      constants.typing_capture = { x = gx, y = gy, w = w, h = h }
      self._force_focus_frames = 6
      self._pre_focus_active = false
      if self.gui._text_inputs then
        for _, ti in ipairs(self.gui._text_inputs) do
          if ti ~= self then ti.is_focused = false end
        end
      end
      self._last_click_t = -100000 -- prevent triple-click from chaining
    else
      -- arm pre-focus so next click routes to menu textbox
      self._pre_focus_active = true
      self._pre_focus_deadline_ms = now_t + 350
      constants.typing_capture = { x = gx, y = gy, w = w, h = h }
      self._force_focus_frames = 3
      self._last_click_t = now_t
      self._last_click_x = constants.mouse_state.position.x or 0
      self._last_click_y = constants.mouse_state.position.y or 0
    end
  elseif constants.mouse_state.left_clicked and not over then
    self.is_focused = false
    constants.is_typing = false
    constants.typing_capture = nil
    self._pre_focus_active = false
  end

  -- input handling when focused
  if self.is_focused and core.graphics and core.graphics.translate_vkey_to_string then
    -- mouse press/release within input to place caret and selection
    local pressed = (constants.mouse_state.left_down and not self._mouse_was_down)
    local released = (self._mouse_was_down and not constants.mouse_state.left_down)
    self._mouse_was_down = constants.mouse_state.left_down
    if pressed and over then
      local x_rel = (constants.mouse_state.position.x - gx)
      local y_rel = (constants.mouse_state.position.y - gy)
      self._caret = clamp(index_from_mouse(self.text or "", x_rel, y_rel), 0, #(self.text or ""))
      self._sel_anchor = self._caret
      self._is_selecting = true
    elseif self._is_selecting and constants.mouse_state.left_down then
      local x_rel = (constants.mouse_state.position.x - gx)
      local y_rel = (constants.mouse_state.position.y - gy)
      self._caret = clamp(index_from_mouse(self.text or "", x_rel, y_rel), 0, #(self.text or ""))
    elseif released then
      self._is_selecting = false
      -- if caret interaction ended and we are no longer focused, hide blocker quickly
      if not self.is_focused then
        constants.is_typing = false
        constants.typing_capture = nil
        self._pre_focus_active = false
        if self._blocker and self._blocker.set_visibility then self._blocker:set_visibility(false) end
      end
    end
    -- Enter handling
    local VK_RETURN = 0x0D
    if key_edge(self, VK_RETURN) then
      if self.multiline then
        self.text = self.text .. "\n"
        self._caret = #(self.text)
        if self.on_change then self.on_change(self, self.text) end
      else
        self.is_focused = false
        constants.is_typing = false
        constants.typing_capture = nil
      end
    end
    -- Backspace
    local VK_BACK = 0x08
    local now_ms = (core.time and core.time()) or 0
    local bs_now = core.input and core.input.is_key_pressed and core.input.is_key_pressed(VK_BACK)
    local function delete_one()
      local txt = self.text or ""
      local s, e = self._sel_anchor, self._caret
      if s and s ~= e then
        local a, b = math.min(s, e), math.max(s, e)
        self.text = (string.sub(txt, 1, a) or "") .. (string.sub(txt, b + 1) or "")
        self._caret = a
        self._sel_anchor = nil
      else
        if self._caret > 0 then
          self.text = (string.sub(txt, 1, self._caret - 1) or "") .. (string.sub(txt, self._caret + 1) or "")
          self._caret = self._caret - 1
        end
      end
      if self.on_change then self.on_change(self, self.text) end
    end
    if bs_now and not self._bs_prev_down then
      delete_one()
      self._bs_next_repeat = now_ms + 350
    elseif bs_now and self._bs_prev_down and now_ms >= (self._bs_next_repeat or now_ms + 1e9) then
      delete_one()
      self._bs_next_repeat = now_ms + 50
    end
    self._bs_prev_down = bs_now
    -- basic character input: scan keys 0x20..0x5A
    for vk = 0x20, 0x5A do
      if vk ~= VK_RETURN and vk ~= VK_BACK then
        if key_edge(self, vk) then
          local ch = core.graphics.translate_vkey_to_string(vk)
          if ch and ch ~= "" then
            local txt = self.text or ""
            local s, e = self._sel_anchor, self._caret
            if s and s ~= e then
              local a, b = math.min(s, e), math.max(s, e)
              self.text = (string.sub(txt, 1, a) or "") .. ch .. (string.sub(txt, b + 1) or "")
              self._caret = a + #ch
              self._sel_anchor = nil
            else
              self.text = (string.sub(txt, 1, self._caret) or "") .. ch .. (string.sub(txt, self._caret + 1) or "")
              self._caret = self._caret + #ch
            end
            if self.on_change then self.on_change(self, self.text) end
          end
        end
      end
    end
  end

  -- render text and selection
  local pad = 6
  local base_y = gy + 2
  local line_h = constants.FONT_SIZE + 2
  local text = self.text or ""
  local lines, starts = split_lines_with_index(text)
  -- draw selection if exists
  if self.is_focused and self._sel_anchor and self._sel_anchor ~= self._caret then
    local a, b = math.min(self._sel_anchor, self._caret), math.max(self._sel_anchor, self._caret)
    for i = 1, #lines do
      local s = starts[i]
      local e = s + #lines[i] - 1
      local sel_s = math.max(a, s)
      local sel_e = math.min(b, e)
      if sel_s <= sel_e then
        local x1 = gx + pad + measure(string.sub(lines[i], 1, sel_s - s))
        local x2 = gx + pad + measure(string.sub(lines[i], 1, sel_e - s + 1))
        local yy = base_y + (i - 1) * line_h
        core.graphics.rect_2d_filled(constants.vec2.new(x1, yy), math.max(1, x2 - x1), line_h, constants.color.new(80,120,200,90), 2)
      end
    end
  end
  -- draw text lines
  for i = 1, #lines do
    local ty = base_y + (i - 1) * line_h
    core.graphics.text_2d(lines[i], constants.vec2.new(gx + pad, ty), constants.FONT_SIZE, constants.color.white(255), false)
  end

  -- caret (blink)
  if self.is_focused then
    self._caret_t = (self._caret_t or 0) + 1
    if (self._caret_t % 60) < 30 then
      local cx_rel, cy_rel = caret_pos_from_index(text, self._caret)
      local cx = gx + pad + cx_rel + 1
      local cy = base_y + cy_rel + 2
      core.graphics.line_2d(constants.vec2.new(cx, cy), constants.vec2.new(cx, cy + line_h - 4), constants.color.white(230), 1)
    end
  else
    self._caret_t = 0
    -- ensure typing flag is reset on blur
    if not self.is_focused then constants.is_typing = false; constants.typing_capture = nil end
  end
end

-- Render an invisible menu window exactly over the input to block clicks
function Input:render_proxy_menu()
  if not (self.is_focused or self._pre_focus_active) or not (self._blocker and self.gui and self.gui.is_open) then
    if self._blocker and self._blocker.set_visibility then self._blocker:set_visibility(false) end
    return
  end
  -- Align a tiny menu window behind our input and render the menu textbox inside
  local gx = self.gui.x + self.x
  local gy = self.gui.y + self.y
  local w, h = self.w, self.h
  -- keep global capture up to date for menu context consumers
  constants.typing_capture = { x = gx, y = gy, w = w, h = h }
  if self._blocker.stop_forcing_size then self._blocker:stop_forcing_size() end
  if self._blocker.set_visibility then self._blocker:set_visibility(true) end
  if self._blocker.force_next_begin_window_pos then
    self._blocker:force_next_begin_window_pos(constants.vec2.new(gx, gy))
  end
  if self._force_focus_frames and self._force_focus_frames > 0 and self._blocker.set_focus then
    self._blocker:set_focus()
  end
  if self._blocker.set_next_window_min_size then
    self._blocker:set_next_window_min_size(constants.vec2.new(w, h))
  end
  if self._blocker.force_window_size then
    self._blocker:force_window_size(constants.vec2.new(w, h))
  end
  if self._blocker.set_next_window_padding then
    self._blocker:set_next_window_padding(constants.vec2.new(0, 0))
  end
  if self._blocker.set_next_window_items_spacing then
    self._blocker:set_next_window_items_spacing(constants.vec2.new(0, 0))
  end
  if self._blocker.set_next_window_items_inner_spacing then
    self._blocker:set_next_window_items_inner_spacing(constants.vec2.new(0, 0))
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
      function()
        -- Ensure input capture in this small window
        if self._blocker.set_next_widget_width then self._blocker:set_next_widget_width(w) end
        if self._blocker.set_focus then self._blocker:set_focus() end
        if self._blocker.block_input_capture then self._blocker:block_input_capture() end
        if self._menu_text and self._menu_text.render then
          -- Render the menu input exactly the same size with no label; make it virtually invisible
          local tr_bg = constants.color.new(0,0,0,1)
          local tr_bd = constants.color.new(0,0,0,1)
          local tr_sel = constants.color.new(0,0,0,1)
          local tr_text = constants.color.new(0,0,0,1)
          if self._menu_text.render_custom then
            self._menu_text:render_custom("", "", tr_bg, tr_bd, tr_sel, tr_text, 0)
          else
            self._menu_text:render("", "")
          end
        end
      end
    )
  end
  if self._force_focus_frames and self._force_focus_frames > 0 then
    self._force_focus_frames = self._force_focus_frames - 1
  end
end

function Input:ensure_hidden_if_inactive()
  if self._blocker and self._blocker.set_visibility then
    local should_hide = (not (self.is_focused or self._pre_focus_active)) or (not (self.gui and self.gui.is_open))
    if should_hide then self._blocker:set_visibility(false) end
  end
end

return Input


