local constants = require("gui/utils/constants")

local Designer = {}
Designer.__index = Designer

local VK_DELETE = 0x2E

local palette_defs = {
  { id = "label",    name = "Label",    w = 140, h = 18,  cat = "Basic" },
  { id = "button",   name = "Button",   w = 120, h = 26,  cat = "Basic" },
  { id = "checkbox", name = "Checkbox", w = 140, h = 20,  cat = "Basic" },
  { id = "combobox", name = "Combobox", w = 160, h = 24,  cat = "Inputs" },
  { id = "slider",   name = "Slider",   w = 180, h = 12,  cat = "Inputs" },
  { id = "listbox",  name = "Listbox",  w = 180, h = 160, cat = "Inputs" },
  { id = "input",    name = "Input",    w = 200, h = 22,  cat = "Inputs" },
  { id = "colorpicker", name = "ColorPicker", w = 160, h = 22, cat = "Inputs" },
    { id = "keybind",  name = "Keybind",  w = 200, h = 22,  cat = "Inputs" },
    { id = "toggle",   name = "Toggle",   w = 46,  h = 22,  cat = "Inputs" },
    { id = "radio",    name = "RadioGroup", w = 160, h = 48, cat = "Inputs" },
    { id = "progress", name = "ProgressBar", w = 200, h = 14, cat = "Basic" },
    { id = "separator",name = "Separator", w = 200, h = 1,  cat = "Basic" },
  { id = "window",   name = "Window",   w = 320, h = 220, cat = "Containers" },
  { id = "optionbox",name = "Optionbox",w = 240, h = 200, cat = "Containers" },
  { id = "spoiler",  name = "Spoiler",  w = 220, h = 24,  cat = "Containers" },
  { id = "panel",    name = "Panel",    w = 220, h = 160, cat = "Containers" },
    { id = "scroll",   name = "ScrollArea", w = 220, h = 160, cat = "Containers" },
}

function Designer:new(owner_gui)
  local o = setmetatable({}, Designer)
  o.gui = owner_gui
  o.components = {}
  o.selected = nil
  o.active_tool = "button"
  o.dragging = false
  o.resizing = false
  o._mouse_was_down = false
  o.snap_enabled = true
  o.enable_resize = false
  -- name/id management and properties UI state
  o._name_counters = {}
  o._prop_name_input = nil
  o._prop_text_input = nil
  o._prop_name_prev_focus = false
  o._prop_name_commit_until = 0
  o._prop_name_valid = true
  -- drag-n-drop from palette state
  o._palette_dragging = false
  o._palette_drag_kind = nil
  o._drag_w = 0
  o._drag_h = 0
  -- context menu state
  o._ctx_open = false
  o._ctx_x, o._ctx_y = 0, 0
  o._ctx_target = nil
  o._edit_size_popup = false
  -- double-click + inline edit state
  o._last_click_t = 0
  o._last_click_target = nil
  o._last_click_x = 0
  o._last_click_y = 0
  o._last_click_was_drag = false
  o._start_drag_x = 0
  o._start_drag_y = 0
  o._snap_guides = nil
  o._inline_input = nil
  o._inline_edit_active = false
  o._inline_just_opened = false
  -- treeview expansion state
  o._tree_expanded = {}
  -- ui toast/hints
  o._toast_until = 0
  o._toast_text = nil
  o._toast_x, o._toast_y = 0, 0
  -- dynamic properties sections (per selected component)
  o._comp_spoilers = nil
  o._last_selected_ref = nil
  return o
end
-- Snap helper: align component to neighbors when close (vertical stack and left-edge align)
function Designer:_compute_snapping(comp)
  if not self.snap_enabled or not comp then return comp.x, comp.y, nil end
  -- effective position helpers (gui-local, including parent offsets)
  local function eff_xy(c)
    local x, y = (c.x or 0), (c.y or 0)
    local p = c.parent
    local guard = 0
    while p do
      -- cycle/overflow guard to prevent infinite loops if a bad parent graph occurs
      guard = guard + 1
      if guard > 16 or p == c then break end
      x = x + (p.x or 0)
      y = y + (p.y or 0)
      p = p.parent
    end
    return x, y
  end
  local threshold = 6
  local comp_eff_x, comp_eff_y = eff_xy(comp)
  local comp_cx = comp_eff_x + math.floor((comp.w or 0) / 2)
  local comp_cy = comp_eff_y + math.floor((comp.h or 0) / 2)
  local scan = nil
  if comp.parent and comp.parent.children then
    scan = comp.parent.children
  else
    scan = self.components
  end
  local best_dx, snap_eff_x = nil, nil
  local best_dy, snap_eff_y = nil, nil
  local guide_v, guide_h = nil, nil
  for i = 1, #scan do
    local other = scan[i]
    if other ~= comp then
      local ox, oy = eff_xy(other)
      -- X snapping: align left edges
      local dx_left = math.abs(comp_eff_x - ox)
      if dx_left <= threshold and (best_dx == nil or dx_left < best_dx) then
        best_dx = dx_left; snap_eff_x = ox; guide_v = { x = self.gui.x + ox }
      end
      -- X snapping: align centers
      local other_cx = ox + math.floor((other.w or 0) / 2)
      local dx_center = math.abs(comp_cx - other_cx)
      if dx_center <= threshold and (best_dx == nil or dx_center < best_dx) then
        best_dx = dx_center
        snap_eff_x = other_cx - math.floor((comp.w or 0) / 2)
        guide_v = { x = self.gui.x + other_cx }
      end
      -- Y snapping: align top edges
      local dy_top = math.abs(comp_eff_y - oy)
      if dy_top <= threshold and (best_dy == nil or dy_top < best_dy) then
        best_dy = dy_top; snap_eff_y = oy; guide_h = { y = self.gui.y + oy }
      end
      -- Y snapping: align centers
      local other_cy = oy + math.floor((other.h or 0) / 2)
      local dy_center = math.abs(comp_cy - other_cy)
      if dy_center <= threshold and (best_dy == nil or dy_center < best_dy) then
        best_dy = dy_center
        snap_eff_y = other_cy - math.floor((comp.h or 0) / 2)
        guide_h = { y = self.gui.y + other_cy }
      end
      -- Y snapping: vertical stack (just below)
      local below_y = oy + (other.h or 0)
      local dy_below = math.abs(comp_eff_y - below_y)
      if dy_below <= threshold and math.abs(comp_eff_x - ox) <= threshold then
        if best_dy == nil or dy_below < best_dy then best_dy = dy_below; snap_eff_y = below_y; guide_h = { y = self.gui.y + below_y } end
      end
    end
  end
  -- convert snapped effective back to local (relative to parent if any)
  local parent_eff_x, parent_eff_y = 0, 0
  if comp.parent then parent_eff_x, parent_eff_y = eff_xy(comp.parent) end
  local nx_eff = (snap_eff_x ~= nil) and snap_eff_x or comp_eff_x
  local ny_eff = (snap_eff_y ~= nil) and snap_eff_y or comp_eff_y
  local nx = nx_eff - parent_eff_x
  local ny = ny_eff - parent_eff_y
  local guides = nil
  if guide_v or guide_h then guides = { v = guide_v, h = guide_h } end
  return nx, ny, guides
end


local function point_in_rect(px, py, x, y, w, h)
  return px >= x and px <= x + w and py >= y and py <= y + h
end

local function get_def(kind)
  for _, d in ipairs(palette_defs) do if d.id == kind then return d end end
  return nil
end

local function is_container_kind(kind)
  return kind == "window" or kind == "panel" or kind == "scroll" or kind == "optionbox" or kind == "spoiler"
end

-- Header inset height for parent windows (child area excludes header for non-invisible styles)
local function get_header_inset(win)
  if not win or win.kind ~= "window" then return 0 end
  local st = tostring(win.style or "window")
  if st == "invisible" then return 0 end
  if st == "leftbar" then return 0 end
  if st == "clean" then return 28 end
  if st == "flat" then return 24 end
  if st == "win95" then return 18 end
  -- defaults for styles with a standard header bar
  local hh = tonumber(win.header_h or 20) or 20
  if hh < 0 then hh = 0 end
  return hh
end

-- For styles with vertical header bar at left, compute left inset instead of top
local function get_left_inset(win)
  if not win or win.kind ~= "window" then return 0 end
  local st = tostring(win.style or "window")
  if st == "leftbar" then return 36 end
  return 0
end

-- Generate a unique component name like label_1, label_2 per kind
function Designer:_generate_name(kind)
  self._name_counters[kind] = (self._name_counters[kind] or 0) + 1
  local base = tostring(kind or "comp"):lower()
  return base .. "_" .. tostring(self._name_counters[kind])
end

function Designer:add_component(kind, x, y)
  local def
  for _, d in ipairs(palette_defs) do if d.id == kind then def = d break end end
  if not def then return end
  local comp = {
    kind = def.id, x = x, y = y, w = def.w, h = def.h,
    text = def.name, title = def.name, multiline = false,
    children = nil, parent = nil,
  }
  -- Assign unique name/id
  local candidate = self:_generate_name(def.id)
  local function exists_name(n)
    for i = 1, #self.components do if self.components[i].name == n then return true end end
    return false
  end
  while exists_name(candidate) do candidate = self:_generate_name(def.id) end
  comp.name = candidate
  table.insert(self.components, comp)
  self.selected = comp
end

-- Remove a component from the canvas, handling parent-child lists
function Designer:_remove_component(comp)
  if not comp then return end
  -- If this component has a parent, remove from the parent's children
  if comp.parent and comp.parent.children then
    local arr = comp.parent.children
    for i = #arr, 1, -1 do
      if arr[i] == comp then table.remove(arr, i) break end
    end
  else
    -- Otherwise remove from root components list
    for i = #self.components, 1, -1 do
      if self.components[i] == comp then table.remove(self.components, i) break end
    end
  end
  if self.selected == comp then self.selected = nil end
  -- Close context menu if it was targeting this component
  if self._ctx_target == comp then self._ctx_open = false; self._ctx_target = nil end
end

local function draw_button(x, y, w, h, label, comp)
  local col_bg = constants.color.new(36, 52, 96, 230)
  local col_border = constants.color.new(32, 40, 70, 255)
  if core.graphics.rect_2d_filled then
    core.graphics.rect_2d_filled(constants.vec2.new(x, y), w, h, col_bg, 4)
  end
  if core.graphics.rect_2d then
    core.graphics.rect_2d(constants.vec2.new(x, y), w, h, col_border, 1, 4)
  end
  if core.graphics.text_2d then
    local fs = (comp and comp.font_size) or constants.FONT_SIZE
    local col = (comp and comp.color) or constants.color.white(255)
    local tw = core.graphics.get_text_width(label, fs, 0)
    local tx = x + math.floor((w - tw) / 2)
    local ty = y + math.floor((h - fs) / 2) - 1
    if comp and comp.bold then
      core.graphics.text_2d(label, constants.vec2.new(tx + 1, ty), fs, col, false)
    end
    core.graphics.text_2d(label, constants.vec2.new(tx, ty), fs, col, false)
    if comp and comp.underline then
      local line_y = ty + fs + 1
      core.graphics.rect_2d_filled(constants.vec2.new(tx, line_y), tw, 1, col, 0)
    end
  end
end

local function draw_component(comp, x, y)
  local k = comp.kind
  local w, h = comp.w, comp.h
  if k == "label" then
    local fs = comp.font_size or constants.FONT_SIZE
    local col = comp.color or constants.color.white(255)
    if comp.bold then
      core.graphics.text_2d(comp.text or "Label", constants.vec2.new(x + 1, y), fs, col, false)
    end
    core.graphics.text_2d(comp.text or "Label", constants.vec2.new(x, y), fs, col, false)
    if comp.underline then
      local tw = core.graphics.get_text_width(comp.text or "Label", fs, 0)
      local line_y = y + fs + 1
      core.graphics.rect_2d_filled(constants.vec2.new(x, line_y), tw, 1, col, 0)
    end
  elseif k == "button" then
    draw_button(x, y, w, h, comp.text or "Button", comp)
  elseif k == "checkbox" then
    local box = 14
    core.graphics.rect_2d_filled(constants.vec2.new(x, y), box, box, constants.color.new(36, 52, 96, 230), 3)
    core.graphics.rect_2d(constants.vec2.new(x, y), box, box, constants.color.new(32, 40, 70, 255), 1, 3)
    core.graphics.text_2d(comp.text or "Checkbox", constants.vec2.new(x + box + 6, y - 2), constants.FONT_SIZE, constants.color.white(255), false)
    comp.w, comp.h = math.max(box + 6 + 80, comp.w), math.max(box, comp.h)
  elseif k == "combobox" then
    core.graphics.rect_2d_filled(constants.vec2.new(x, y), w, h, constants.color.new(20, 26, 42, 245), 4)
    core.graphics.rect_2d(constants.vec2.new(x, y), w, h, constants.color.new(32, 40, 70, 255), 1, 4)
    core.graphics.text_2d(comp.text or "Combobox", constants.vec2.new(x + 8, y - 1), constants.FONT_SIZE, constants.color.white(255), false)
  elseif k == "slider" then
    local th = 12
    core.graphics.rect_2d_filled(constants.vec2.new(x, y), w, th, constants.color.new(16, 20, 34, 235), 4)
    core.graphics.rect_2d(constants.vec2.new(x, y), w, th, constants.color.new(32, 40, 70, 255), 1, 4)
    core.graphics.rect_2d_filled(constants.vec2.new(x + math.floor(w/2) - 6, y - 2), 12, th + 4, constants.color.white(220), 3)
    comp.h = th
  elseif k == "listbox" then
    core.graphics.rect_2d_filled(constants.vec2.new(x, y), w, h, constants.color.new(16, 20, 34, 235), 6)
    core.graphics.rect_2d(constants.vec2.new(x, y), w, h, constants.color.new(32, 40, 70, 255), 1, 6)
    core.graphics.rect_2d_filled(constants.vec2.new(x, y), w, 18, constants.color.new(56, 80, 140, 230), 6)
    core.graphics.text_2d("Listbox", constants.vec2.new(x + 8, y + 2), constants.FONT_SIZE, constants.color.white(255), false)
  elseif k == "input" then
    core.graphics.rect_2d_filled(constants.vec2.new(x, y), w, h, constants.color.new(20, 26, 42, 245), 4)
    core.graphics.rect_2d(constants.vec2.new(x, y), w, h, constants.color.new(32, 40, 70, 255), 1, 4)
    core.graphics.text_2d(comp.text or "Input", constants.vec2.new(x + 6, y - 1), constants.FONT_SIZE, constants.color.white(255), false)
  elseif k == "colorpicker" then
    -- draw preview to match real ColorPicker (closed state), honoring styles
    local function draw_checker(cx, cy, cw, ch)
      local c1 = constants.color.new(200,200,200,255)
      local c2 = constants.color.new(240,240,240,255)
      local sz = 6
      for yy = cy, cy + ch - 1, sz do
        for xx = cx, cx + cw - 1, sz do
          local even = (math.floor((xx - cx)/sz) + math.floor((yy - cy)/sz)) % 2 == 0
          if core.graphics.rect_2d_filled then
            core.graphics.rect_2d_filled(constants.vec2.new(xx, yy), math.min(sz, cx + cw - xx), math.min(sz, cy + ch - yy), even and c1 or c2, 0)
          end
        end
      end
    end
    local bd = constants.color.new(18,22,30,220)
    local base_bg = constants.color.new(30,46,80,220)
    local csrc = comp.color or comp.default_color or { r = 240, g = 240, b = 245, a = 255 }
    local label = comp.placeholder or "Choose"
    local fs = (constants.FONT_SIZE or 14)
    local style = tostring(comp.style or "classic")
    -- outer frame
    core.graphics.rect_2d_filled(constants.vec2.new(x, y), w, h, base_bg, 6)
    core.graphics.rect_2d(constants.vec2.new(x, y), w, h, bd, 1, 6)
    if style == "classic" then
      local sw = h - 6
      local sx, sy = x + 4, y + 3
      draw_checker(sx, sy, sw, sw)
      core.graphics.rect_2d_filled(constants.vec2.new(sx, sy), sw, sw, constants.color.new(csrc.r or 240, csrc.g or 240, csrc.b or 245, csrc.a or 255), 3)
      core.graphics.rect_2d(constants.vec2.new(sx, sy), sw, sw, bd, 1, 3)
      local px0 = x + sw + 8
      local pw0 = math.max(0, w - (sw + 12))
      local col = constants.color.new(csrc.r or 240, csrc.g or 240, csrc.b or 245, math.min(235, (csrc.a or 255)))
      core.graphics.rect_2d_filled(constants.vec2.new(px0, y + 3), pw0, h - 6, col, 4)
      core.graphics.rect_2d(constants.vec2.new(px0, y + 3), pw0, h - 6, bd, 1, 4)
      local tw = (core.graphics.get_text_width and core.graphics.get_text_width(label, fs, 0)) or 0
      local tx = px0 + math.max(0, math.floor((pw0 - tw) / 2))
      local ty = y + math.floor((h - fs) / 2) - 1
      local lum = (0.299 * (csrc.r or 240) + 0.587 * (csrc.g or 240) + 0.114 * (csrc.b or 245))
      local txt_col = (lum > 140) and constants.color.new(20,20,24,240) or constants.color.white(245)
      core.graphics.text_2d(label, constants.vec2.new(tx, ty), fs, txt_col, false)
    elseif style == "split" then
      local split_w = math.max(24, math.floor(w * 0.4))
      local col = constants.color.new(csrc.r or 240, csrc.g or 240, csrc.b or 245, math.min(235, (csrc.a or 255)))
      core.graphics.rect_2d_filled(constants.vec2.new(x + 2, y + 2), split_w - 4, h - 4, col, 5)
      core.graphics.rect_2d(constants.vec2.new(x + 2, y + 2), split_w - 4, h - 4, bd, 1, 5)
      core.graphics.rect_2d_filled(constants.vec2.new(x + split_w, y + 4), 2, h - 8, constants.color.new(18,22,30,180), 1)
      local tw = (core.graphics.get_text_width and core.graphics.get_text_width(label, fs, 0)) or 0
      local tx = x + split_w + math.max(6, math.floor((w - split_w - tw) / 2))
      local ty = y + math.floor((h - fs) / 2) - 1
      core.graphics.text_2d(label, constants.vec2.new(tx, ty), fs, constants.color.white(245), false)
    elseif style == "neon" then
      -- Neon: glow outlines, colored left dot, centered label, underline
      local accent_r, accent_g, accent_b = csrc.r or 240, csrc.g or 240, csrc.b or 245
      local pulse = 0.5
      if core.time then
        local t = core.time() / 1000.0
        pulse = 0.5 + 0.5 * math.sin(t * 3.2)
      end
      local glow_a = math.floor(120 + 90 * pulse)
      local glow = constants.color.new(accent_r, accent_g, accent_b, glow_a)
      core.graphics.rect_2d(constants.vec2.new(x, y), w, h, glow, 2, 8)
      core.graphics.rect_2d(constants.vec2.new(x + 2, y + 2), w - 4, h - 4, constants.color.new(accent_r, accent_g, accent_b, math.floor(glow_a * 0.6)), 1, 7)
      local dot_d = h - 10
      local dx = x + 6
      local dy = y + 5
      core.graphics.rect_2d_filled(constants.vec2.new(dx, dy), dot_d, dot_d, constants.color.new(accent_r, accent_g, accent_b, csrc.a or 255), math.floor(dot_d/2))
      core.graphics.rect_2d(constants.vec2.new(dx, dy), dot_d, dot_d, constants.color.new(accent_r, accent_g, accent_b, 255), 1, math.floor(dot_d/2))
      local tw = (core.graphics.get_text_width and core.graphics.get_text_width(label, fs, 0)) or 0
      local tx = x + math.max(dot_d + 12, math.floor((w - tw)/2))
      local ty = y + math.floor((h - fs) / 2) - 1
      core.graphics.text_2d(label, constants.vec2.new(tx, ty), fs, constants.color.white(250), false)
      core.graphics.rect_2d_filled(constants.vec2.new(x + 8, y + h - 3), w - 16, 2, glow, 2)
    elseif style == "glass" then
      -- Glassmorphism: translucent inner card, glossy top band, color capsule
      local glass_bg = constants.color.new(255, 255, 255, 22)
      local glass_bd = constants.color.new(200, 220, 255, 180)
      core.graphics.rect_2d_filled(constants.vec2.new(x + 2, y + 2), w - 4, h - 4, glass_bg, 8)
      core.graphics.rect_2d(constants.vec2.new(x + 2, y + 2), w - 4, h - 4, glass_bd, 1, 8)
      local gloss_h = math.max(2, math.floor(h * 0.35))
      core.graphics.rect_2d_filled(constants.vec2.new(x + 4, y + 3), w - 8, gloss_h, constants.color.new(255,255,255,26), 6)
      local cap_w = h - 6
      local cxp = x + 5
      local cyp = y + 3
      draw_checker(cxp, cyp, cap_w, cap_w)
      core.graphics.rect_2d_filled(constants.vec2.new(cxp, cyp), cap_w, cap_w, constants.color.new(csrc.r or 240, csrc.g or 240, csrc.b or 245, csrc.a or 255), math.floor(cap_w/2))
      core.graphics.rect_2d(constants.vec2.new(cxp, cyp), cap_w, cap_w, constants.color.new(18,22,30,160), 1, math.floor(cap_w/2))
      local tw = (core.graphics.get_text_width and core.graphics.get_text_width(label, fs, 0)) or 0
      local tx = x + math.max(cap_w + 10, math.floor((w - tw)/2))
      local ty = y + math.floor((h - fs) / 2) - 1
      core.graphics.text_2d(label, constants.vec2.new(tx, ty), fs, constants.color.white(240), false)
    else
      local dot_d = h - 8
      local dx = x + 6
      local dy = y + 4
      core.graphics.rect_2d_filled(constants.vec2.new(dx, dy), dot_d, dot_d, constants.color.new(csrc.r or 240, csrc.g or 240, csrc.b or 245, csrc.a or 255), math.floor(dot_d/2))
      core.graphics.rect_2d(constants.vec2.new(dx, dy), dot_d, dot_d, bd, 1, math.floor(dot_d/2))
      local tw = (core.graphics.get_text_width and core.graphics.get_text_width(label, fs, 0)) or 0
      local tx = x + math.max(dot_d + 10, math.floor((w - tw)/2))
      local ty = y + math.floor((h - fs) / 2) - 1
      core.graphics.text_2d(label, constants.vec2.new(tx, ty), fs, constants.color.white(245), false)
    end
  elseif k == "panel" then
    core.graphics.rect_2d_filled(constants.vec2.new(x, y), w, h, constants.color.new(14, 18, 30, 220), 6)
    core.graphics.rect_2d(constants.vec2.new(x, y), w, h, constants.color.new(32, 40, 70, 255), 1, 6)
    core.graphics.rect_2d_filled(constants.vec2.new(x, y), w, 20, constants.color.new(56, 80, 140, 230), 6)
    core.graphics.text_2d(comp.title or "Panel", constants.vec2.new(x + 8, y + 2), constants.FONT_SIZE, constants.color.white(255), false)
  elseif k == "keybind" then
    core.graphics.rect_2d_filled(constants.vec2.new(x, y), w, 22, constants.color.new(20, 26, 42, 245), 4)
    core.graphics.rect_2d(constants.vec2.new(x, y), w, 22, constants.color.new(32, 40, 70, 255), 1, 4)
    core.graphics.text_2d("Keybind", constants.vec2.new(x + 8, y - 1), constants.FONT_SIZE, constants.color.white(255), false)
  elseif k == "toggle" then
    core.graphics.rect_2d_filled(constants.vec2.new(x, y), 46, 22, constants.color.new(60,70,95,210), 11)
    core.graphics.rect_2d_filled(constants.vec2.new(x + 1, y + 1), 20, 20, constants.color.white(230), 9)
  elseif k == "radio" then
    core.graphics.rect_2d(constants.vec2.new(x, y), w, h, constants.color.new(32, 40, 70, 255), 1, 6)
    core.graphics.text_2d("RadioGroup", constants.vec2.new(x + 6, y + 2), constants.FONT_SIZE, constants.color.white(255), false)
  elseif k == "progress" then
    core.graphics.rect_2d_filled(constants.vec2.new(x, y), w, 14, constants.color.new(16,20,34,235), 4)
    core.graphics.rect_2d(constants.vec2.new(x, y), w, 14, constants.color.new(32, 40, 70, 255), 1, 4)
    core.graphics.rect_2d_filled(constants.vec2.new(x, y), math.floor(w*0.5), 14, constants.color.new(120,160,230,255), 4)
  elseif k == "separator" then
    core.graphics.rect_2d(constants.vec2.new(x, y), w, 1, constants.color.new(32,40,70,200), 1, 0)
  elseif k == "scroll" then
    core.graphics.rect_2d_filled(constants.vec2.new(x, y), w, h, constants.color.new(14, 18, 30, 220), 6)
    core.graphics.rect_2d(constants.vec2.new(x, y), w, h, constants.color.new(32, 40, 70, 255), 1, 6)
  elseif k == "optionbox" then
    -- header + body outline
    core.graphics.rect_2d_filled(constants.vec2.new(x, y), w, h, constants.color.new(14,18,30,220), 6)
    core.graphics.rect_2d(constants.vec2.new(x, y), w, h, constants.color.new(32,40,70,255), 1, 6)
    core.graphics.text_2d(comp.title or "Optionbox", constants.vec2.new(x + 8, y + 2), constants.FONT_SIZE, constants.color.white(235), false)
  elseif k == "spoiler" then
    local hdr_h = 20
    core.graphics.rect_2d_filled(constants.vec2.new(x, y), w, hdr_h, constants.color.new(20,26,42,235), 4)
    core.graphics.rect_2d(constants.vec2.new(x, y), w, comp.h or 24, constants.color.new(32,40,70,255), 1, 4)
    core.graphics.text_2d(comp.title or "Spoiler", constants.vec2.new(x + 20, y + 2), constants.FONT_SIZE, constants.color.white(235), false)
  elseif k == "window" then
    local function to_col(c)
      if type(c) == "table" then return constants.color.new(c.r or 0, c.g or 0, c.b or 0, c.a or 255) end
      return c
    end
    local style = comp.style or "box"
    local border = to_col(comp.border_col or { r = 32, g = 40, b = 70, a = 255 })
    if style == "window" then
      local hb = to_col(comp.header_col or { r = 56, g = 80, b = 140, a = 230 })
      local bg = to_col(comp.bg_col or { r = 14, g = 18, b = 30, a = 220 })
      core.graphics.rect_2d_filled(constants.vec2.new(x, y), w, h, bg, 6)
      core.graphics.rect_2d(constants.vec2.new(x, y), w, h, border, 1, 6)
      core.graphics.rect_2d_filled(constants.vec2.new(x, y), w, 20, hb, 6)
      local tc = to_col(comp.title_col or { r = 240, g = 240, b = 245, a = 255 })
      core.graphics.text_2d(comp.title or comp.name or "Window", constants.vec2.new(x + 8, y + 2), constants.FONT_SIZE, tc, false)
      if not comp.children or #comp.children == 0 then
      if not comp.children or #comp.children == 0 then
        local hint = "(drop items here)"
        core.graphics.text_2d(hint, constants.vec2.new(x + 8, y + 26), 12, constants.color.white(120), false)
      end
      end
    elseif style == "box" then
      local bg = to_col(comp.bg_col or { r = 14, g = 18, b = 30, a = 220 })
      core.graphics.rect_2d_filled(constants.vec2.new(x, y), w, h, bg, 6)
      core.graphics.rect_2d(constants.vec2.new(x, y), w, h, border, 1, 6)
      local tc = to_col(comp.title_col or { r = 240, g = 240, b = 245, a = 255 })
      core.graphics.text_2d(comp.title or comp.name or "Window", constants.vec2.new(x + 8, y + 2), constants.FONT_SIZE, tc, false)
    elseif style ~= "box" and style ~= "window" then
      -- Reduce to basic styles only (box/invisible) for now
      local bg = to_col(comp.bg_col or { r = 14, g = 18, b = 30, a = 220 })
      core.graphics.rect_2d_filled(constants.vec2.new(x, y), w, h, bg, 6)
      core.graphics.rect_2d(constants.vec2.new(x, y), w, h, border, 1, 6)
      local tc = to_col(comp.title_col or { r = 240, g = 240, b = 245, a = 255 })
      core.graphics.text_2d(comp.title or comp.name or "Window", constants.vec2.new(x + 8, y + 2), constants.FONT_SIZE, tc, false)
    else
      -- invisible: draw only a thin border as a design-time hint
      core.graphics.rect_2d(constants.vec2.new(x, y), w, h, border, 1, 6)
      local tc = to_col(comp.title_col or { r = 240, g = 240, b = 245, a = 200 })
      core.graphics.text_2d(comp.title or comp.name or "Window", constants.vec2.new(x + 8, y + 2), constants.FONT_SIZE, tc, false)
    end
  end
  -- selection handle
  if comp.__selected then
    local sel = constants.color.new(200, 220, 255, 180)
    -- Always show a light outline when selected (including labels)
    core.graphics.rect_2d(constants.vec2.new(x - 1, y - 1), w + 2, h + 2, sel, 1, 6)
    -- Window supports resizing via bottom-right handle
    if comp.kind == "window" then
      core.graphics.rect_2d_filled(constants.vec2.new(x + w - 8, y + h - 8), 8, 8, sel, 2)
    end
  end
end

function Designer:render(ox, oy)
  -- place everything INSIDE the tab content rect
  local gx, gy = self.gui.x, self.gui.y
  local base_x = gx + ox
  local base_y = gy + oy
  -- capture mouse state early so we can use edge flags in palette too
  local m = constants.mouse_state.position
  local down = constants.mouse_state.left_down
  local pressed = (down and not self._mouse_was_down)
  local released = (self._mouse_was_down and not down)
  local now_ms = (core.time and core.time()) or 0
  local content_w, content_h = 0, 0
  if self.gui._tabs and self.gui._tabs.get_content_size then
    content_w, content_h = self.gui._tabs:get_content_size()
  else
    content_w = self.gui.width - (ox + 16)
    content_h = self.gui.height - (oy + 16)
  end
  -- Left palette panel
  local palette_w = 200
  local palette_x = base_x
  local palette_y = base_y + 12 -- shift panel down a bit
  -- Layout constants: place properties to the RIGHT of the canvas (not overlapping)
  local side_gap = 10
  local props_w = 250
  local canvas_x, canvas_y = base_x + palette_w + side_gap, base_y
  -- Reserve space for properties panel plus a gap between canvas and properties
  local canvas_w, canvas_h = math.max(0, content_w - palette_w - side_gap - props_w - side_gap), content_h

  -- Draw palette left panel with categories
  do
    local col_bg = constants.color.new(14, 18, 30, 220)
    local col_bd = constants.color.new(32, 40, 70, 255)
    -- reserve space below panel for Export button (outside the panel)
    local export_h = 22
    local export_gap = 8
    local panel_h = math.max(0, content_h - export_h - export_gap)
    core.graphics.rect_2d_filled(constants.vec2.new(palette_x, palette_y), palette_w, panel_h, col_bg, 6)
    core.graphics.rect_2d(constants.vec2.new(palette_x, palette_y), palette_w, panel_h, col_bd, 1, 6)
    -- Title
    if core.graphics.text_2d then
      core.graphics.text_2d("Components", constants.vec2.new(palette_x + 10, palette_y + 6), constants.FONT_SIZE, constants.color.white(255), false)
    end
    -- Options section
    local opt_y = palette_y + 26
    do
      -- section label
      core.graphics.text_2d("Options", constants.vec2.new(palette_x + 10, opt_y), constants.FONT_SIZE, constants.color.white(235), false)
      local row_y = opt_y + 18
      local cb_x, cb_y, cb_s = palette_x + 12, row_y + 2, 12
      -- box
      core.graphics.rect_2d(constants.vec2.new(cb_x, cb_y), cb_s, cb_s, col_bd, 1, 2)
      if self.snap_enabled then
        core.graphics.rect_2d_filled(constants.vec2.new(cb_x + 2, cb_y + 2), cb_s - 4, cb_s - 4, constants.color.new(120, 190, 255, 255), 2)
      end
      core.graphics.text_2d("Enable snapping", constants.vec2.new(cb_x + cb_s + 8, row_y), constants.FONT_SIZE, constants.color.white(240), false)
      -- toggle on click
      if point_in_rect(constants.mouse_state.position.x, constants.mouse_state.position.y, cb_x, cb_y, cb_s + 160, cb_s + 4) and constants.mouse_state.left_clicked then
        self.snap_enabled = not self.snap_enabled
      end
    end
    local list_y = opt_y + 40
    local list_y_limit = palette_y + panel_h - 10
    -- Build categories map
    local cats = {}
    for i = 1, #palette_defs do
      local d = palette_defs[i]
      local c = d.cat or "Other"
      cats[c] = cats[c] or {}
      table.insert(cats[c], d)
    end
    -- Deterministic order (Containers first)
    local order = { "Containers", "Basic", "Inputs", "Other" }
    for oi = 1, #order do
      local cname = order[oi]
      local arr = cats[cname]
      if arr and #arr > 0 then
        -- Category header (non-button look): left accent + label + underline
        local accent = constants.color.new(120, 190, 255, 255)
        local hdr_h = 16
        if core.graphics.rect_2d_filled then
          core.graphics.rect_2d_filled(constants.vec2.new(palette_x + 6, list_y + 2), 3, hdr_h - 4, accent, 2)
        end
        core.graphics.text_2d(cname, constants.vec2.new(palette_x + 14, list_y + 0), constants.FONT_SIZE, constants.color.white(235), false)
        if core.graphics.rect_2d then
          core.graphics.rect_2d(constants.vec2.new(palette_x + 6, list_y + hdr_h + 2), palette_w - 12, 1, col_bd, 1, 0)
        end
        list_y = list_y + hdr_h + 6
        -- Items
        for ii = 1, #arr do
          local d = arr[ii]
          local ih = 18
          local iw = palette_w - 16
          local ix = palette_x + 8
          local iy = list_y
          if iy + ih > list_y_limit then break end
          local over = point_in_rect(constants.mouse_state.position.x, constants.mouse_state.position.y, ix, iy, iw, ih)
          local bg = over and constants.color.new(76, 110, 180, 255) or constants.color.new(36, 52, 96, 220)
          core.graphics.rect_2d_filled(constants.vec2.new(ix, iy), iw, ih, bg, 4)
          core.graphics.rect_2d(constants.vec2.new(ix, iy), iw, ih, col_bd, 1, 4)
          core.graphics.text_2d(d.name, constants.vec2.new(ix + 8, iy - 1), constants.FONT_SIZE, constants.color.white(255), false)
          -- start drag on press
          if over and pressed then
            self._palette_dragging = true
            self._palette_drag_kind = d.id
            self._drag_w = d.w
            self._drag_h = d.h
          end
          list_y = list_y + ih + 6
        end
        list_y = list_y + 6
      end
    end

    -- Export button outside, just below the component panel
    do
      local bw, bh = palette_w - 20, export_h
      local ex_x = palette_x + 10
      local ex_y = palette_y + panel_h + export_gap
      core.graphics.rect_2d_filled(constants.vec2.new(ex_x, ex_y), bw, bh, constants.color.new(86,120,200,230), 4)
      core.graphics.rect_2d(constants.vec2.new(ex_x, ex_y), bw, bh, col_bd, 1, 4)
      local label = "Export Lua"
      local tw = (core.graphics.get_text_width and core.graphics.get_text_width(label, constants.FONT_SIZE, 0)) or 60
      local tx = ex_x + math.floor((bw - tw) / 2)
      local ty = ex_y + math.floor((bh - (constants.FONT_SIZE or 14)) / 2) - 1
      core.graphics.text_2d(label, constants.vec2.new(tx, ty), constants.FONT_SIZE, constants.color.white(255), false)
      if point_in_rect(constants.mouse_state.position.x, constants.mouse_state.position.y, ex_x, ex_y, bw, bh) and pressed then
        self:export()
      end
    end
  end

  -- Canvas background
  core.graphics.rect_2d_filled(constants.vec2.new(canvas_x, canvas_y), canvas_w, canvas_h, constants.color.new(10, 12, 18, 160), 6)
  core.graphics.rect_2d(constants.vec2.new(canvas_x, canvas_y), canvas_w, canvas_h, constants.color.new(32,40,70,255), 1, 6)

  self._mouse_was_down = down

  -- Handle palette drag-and-drop creation
  if self._palette_dragging then
    -- draw ghost of the component following the cursor
    local gx = m.x - math.floor(self._drag_w / 2)
    local gy = m.y - math.floor(self._drag_h / 2)
    local ghost_bg = constants.color.new(20, 30, 50, 160)
    local ghost_bd = constants.color.new(120, 190, 255, 230)
    if core.graphics.rect_2d_filled then
      core.graphics.rect_2d_filled(constants.vec2.new(gx, gy), self._drag_w, self._drag_h, ghost_bg, 6)
    end
    if core.graphics.rect_2d then
      core.graphics.rect_2d(constants.vec2.new(gx, gy), self._drag_w, self._drag_h, ghost_bd, 1, 6)
    end
    if not down then
      -- drop: create only if inside canvas
      if point_in_rect(m.x, m.y, canvas_x, canvas_y, canvas_w, canvas_h) and self._palette_drag_kind then
        local def = get_def(self._palette_drag_kind)
        local cx = m.x - self.gui.x - math.floor((def and def.w or self._drag_w) / 2)
        local cy = m.y - self.gui.y - math.floor((def and def.h or self._drag_h) / 2)
        -- Parent to window if the drop is inside a window and the kind supports children
        local parent = nil
        for i = #self.components, 1, -1 do
          local c = self.components[i]
          if c.kind == "window" then
            local wx, wy = self.gui.x + c.x, self.gui.y + c.y
            if point_in_rect(m.x, m.y, wx, wy, c.w, c.h) then parent = c; break end
          end
        end
        -- Enforce: Window is the ONLY base container. All other kinds must be dropped inside a Window.
        local new_kind = self._palette_drag_kind
        if (not parent) and (new_kind ~= "window") then
          -- do not create; show a brief pulsing warning
          if self.gui and self.gui.AddWarning then
            local msg = "Drop inside a Window"
            local wx = m.x - self.gui.x + 12
            local wy = m.y - self.gui.y + 12
            self.gui:AddWarning(msg, wx, wy, 1400)
          else
            -- fallback toast (unlikely)
            self._toast_text = "Drop inside a Window"
            self._toast_until = (core.time() or 0) + 1400
            self._toast_x, self._toast_y = m.x + 12, m.y + 12
          end
        else
        -- clamp to canvas bounds (full component inside)
        do
          local min_x = (canvas_x - self.gui.x)
          local min_y = (canvas_y - self.gui.y)
          local max_x = (canvas_x + canvas_w) - self.gui.x - (def and def.w or self._drag_w)
          local max_y = (canvas_y + canvas_h) - self.gui.y - (def and def.h or self._drag_h)
          cx = math.max(min_x, math.min(cx, max_x))
          cy = math.max(min_y, math.min(cy, max_y))
        end
          self:add_component(new_kind, cx, cy)
          if parent and new_kind ~= "window" then
            local child = self.selected
            if child and (child.parent ~= parent) then
              -- Convert position to parent's local coordinates; exclude header area for non-invisible styles
              local inset_y = get_header_inset(parent)
              child.x = (child.x or 0) - (parent.x or 0)
              child.y = (child.y or 0) - (parent.y or 0) - inset_y
              child.parent = parent
              parent.children = parent.children or {}
              table.insert(parent.children, child)
              -- Optionbox specifics: when dropping a spoiler into an optionbox, snap height
              if parent.kind == "optionbox" and new_kind == "spoiler" then
                child.h = child.h or 24
              end
              -- Clamp child inside parent's bounds immediately on drop
              local left_inset = get_left_inset(parent)
              local pw = (parent.w or 0) - left_inset
              local ph = (parent.h or 0) - inset_y
              local cw = child.w or 0
              local ch = child.h or 0
              local max_cx = math.max(0, pw - cw)
              local max_cy = math.max(0, ph - ch)
              child.x = math.max(0, math.min(child.x or 0, max_cx))
              child.y = math.max(0, math.min(child.y or 0, max_cy))
            end
            -- Do not instantiate live controls for design-time components
          end
        -- On the drop frame, skip snapping to avoid feedback loops; only clamp
        if self.selected then
          local aw = self.selected.w or 0
          local ah = self.selected.h or 0
          if parent then
            local inset_y = get_header_inset(parent)
            local max_x = math.max(0, (parent.w or 0) - aw)
            local max_y = math.max(0, ((parent.h or 0) - inset_y) - ah)
            self.selected.x = math.max(0, math.min(self.selected.x or 0, max_x))
            self.selected.y = math.max(0, math.min(self.selected.y or 0, max_y))
          else
            local min_x = (canvas_x - self.gui.x)
            local min_y = (canvas_y - self.gui.y)
            local max_x = (canvas_x + canvas_w) - self.gui.x - aw
            local max_y = (canvas_y + canvas_h) - self.gui.y - ah
            self.selected.x = math.max(min_x, math.min(self.selected.x or 0, max_x))
            self.selected.y = math.max(min_y, math.min(self.selected.y or 0, max_y))
          end
        end
        self._snap_guides = nil
        end
      end
      self._palette_dragging = false
      self._palette_drag_kind = nil
      self._drag_w = 0
      self._drag_h = 0
    end
  end

  -- If inline editor is active and mouse press occurs over its rect, do not start selection/drag
  local inline_over = false
  if pressed and self._inline_edit_active and self._inline_input then
    local ix, iy, iw, ih = self.gui.x + (self._inline_input.x or 0), self.gui.y + (self._inline_input.y or 0), self._inline_input.w or 0, self._inline_input.h or 0
    inline_over = point_in_rect(m.x, m.y, ix, iy, iw, ih)
  end

  if pressed and not inline_over then
    -- only selection / move / resize start (no spawn on click)
    local hit_any = false
    -- If a color picker popup is open, and we click inside it, suppress canvas interactions
    do
      local cps = self.gui._color_pickers
      if cps then
        for i = 1, #cps do
          local cp = cps[i]
          if cp and cp.is_open and cp._popup_abs then
            local r = cp._popup_abs
            if point_in_rect(constants.mouse_state.position.x, constants.mouse_state.position.y, r.x, r.y, r.w, r.h) then
              hit_any = true
              break
            end
          end
        end
      end
    end
    if hit_any then
      -- do not start move/resize/select when clicking inside color picker popup
    else
    for i = #self.components, 1, -1 do
      local c = self.components[i]
      local parent_offset_x = (c.parent and c.parent.x) or 0
      local parent_offset_y = (c.parent and c.parent.y) or 0
      local header_inset = (c.parent and get_header_inset(c.parent)) or 0
      local cx, cy = self.gui.x + parent_offset_x + c.x, self.gui.y + parent_offset_y + header_inset + c.y
      -- resize: allow for window components only
      local hs = 10
      if c.kind == "window" and point_in_rect(m.x, m.y, cx + c.w - hs, cy + c.h - hs, hs, hs) then
        self.selected = c
        self.resizing = true
        self.resize_corner = "br"
        self.dragging = true
        hit_any = true
        break
      end
      -- move/selection or double-click edit
      if point_in_rect(m.x, m.y, cx, cy, c.w, c.h) then
        local dt = now_ms - (self._last_click_t or 0)
        local moved_since_last = (math.abs(m.x - (self._last_click_x or m.x)) > 3) or (math.abs(m.y - (self._last_click_y or m.y)) > 3)
        local is_double = (self._last_click_target == c) and (dt <= 350) and (not self._last_click_was_drag) and (not moved_since_last)
        self._last_click_target = c
        self._last_click_t = now_ms
        self._last_click_x = m.x
        self._last_click_y = m.y
        self._last_click_was_drag = false
        self.selected = c
        -- If we clicked inside a window, mark it as the nesting parent for subsequent creations
        if c.kind == "window" then
          self._active_parent = c
        else
          -- clicking any non-window component does not change the active parent
        end
        if is_double then
          -- Inline text edit for text-capable components (label, button, checkbox, combobox, panel)
          if c.kind == "label" or c.kind == "button" or c.kind == "checkbox" or c.kind == "combobox" or c.kind == "panel" then
            if not self._inline_input then
              self._inline_input = self.gui:AddInput(0, 0, 120, 20, { multiline = false, text = "", transparent = true }, function(_, val)
                if self._inline_target then
                  if self._inline_target.kind == "panel" then
                    self._inline_target.title = val
                  else
                    self._inline_target.text = val
                  end
                end
              end)
              self._inline_input:set_visible_if(function() return self._inline_edit_active end)
            end
            -- switch inline target to the newly double-clicked component
            self._inline_target = c
            c.__editing = true
            -- overlay the entire component area so edit stays active regardless of click position
            do
              local px = (c.parent and c.parent.x) or 0
              local py = (c.parent and c.parent.y) or 0
              self._inline_input.x = px + c.x
              self._inline_input.y = py + c.y
            end
            self._inline_input.w = c.w
            self._inline_input.h = c.h
            self._inline_edit_active = true
            self._inline_just_opened = true
            self._inline_input.is_focused = true
            constants.is_typing = true
            local cur = tostring((c.kind == "panel" and c.title) or c.text or "")
              self._inline_input:set_text(cur)
            if self._inline_input and self._inline_input.select_all then self._inline_input:select_all() end
            -- do not start dragging on this frame
            self.dragging = false
            self.resizing = false
            self.resize_corner = nil
          else
            -- fallback: open properties popup for non text-editable components
            self.dragging = false
            self.resizing = false
            self.resize_corner = nil
            self._edit_props_popup = true
            self._props_x = self.gui.x + c.x + c.w + 10
            self._props_y = self.gui.y + c.y
            self._props_just_opened = true
          end
        else
          self.dragging = true
          self.resizing = false
          self.resize_corner = nil
          self._offx = m.x - cx
          self._offy = m.y - cy
          self._start_drag_x = m.x
          self._start_drag_y = m.y
        end
        hit_any = true
        break
      end
    end
    -- If mouse press did not hit any component and is inside canvas, clear selection
    if not hit_any and point_in_rect(m.x, m.y, canvas_x, canvas_y, canvas_w, canvas_h) then
      if self.selected then self.selected.__selected = false end
      self.selected = nil
      self.dragging = false
      self.resizing = false
      self.resize_corner = nil
      self._ctx_open = false
      -- close inline edit if active
      self._inline_edit_active = false
      self._inline_target = nil
    end
    end
  end

  -- Right-click context menu open (disabled when right-clicking over inline editor)
  if constants.mouse_state.right_clicked and not (self._inline_edit_active and self._inline_input and point_in_rect(m.x, m.y, self.gui.x + self._inline_input.x, self.gui.y + self._inline_input.y, self._inline_input.w or 0, self._inline_input.h or 0)) then
    self._ctx_open = false
    self._edit_size_popup = false
    self._ctx_target = nil
    for i = #self.components, 1, -1 do
      local c = self.components[i]
      local pox = (c.parent and c.parent.x) or 0
      local poy = (c.parent and c.parent.y) or 0
      local cx, cy = self.gui.x + pox + c.x, self.gui.y + poy + c.y
      if point_in_rect(m.x, m.y, cx, cy, c.w, c.h) then
        self.selected = c
        self._ctx_open = true
        self._ctx_target = c
        self._ctx_x, self._ctx_y = m.x, m.y
        break
      end
    end
  end

  -- Draw components and process selection/move/resize
  local selected = nil
  for i = 1, #self.components do self.components[i].__selected = false end
  -- selection/move start
  -- removed duplicate left_clicked selection block; handled in 'pressed' above for stable double-click detection
  if self.selected then
    self.selected.__selected = true
    if self.dragging then
      if down then
        -- Handle resizing for Window
        if self.resizing and self.selected and self.selected.kind == "window" then
          local sel = self.selected
          -- Minimum size: keep all children fully visible inside the window
          local minw, minh = 60, 60
          if sel.children and #sel.children > 0 then
            local req_w, req_h = 0, 0
            for j = 1, #sel.children do
              local ch = sel.children[j]
              local cw = (ch and ch.w) or 0
              local chh = (ch and ch.h) or 0
              local cx = (ch and ch.x) or 0
              local cy = (ch and ch.y) or 0
              if cw > 0 then req_w = math.max(req_w, cx + cw) end
              if chh > 0 then req_h = math.max(req_h, cy + chh) end
            end
            -- Small cushion to avoid zero-margin clipping
            minw = math.max(minw, req_w)
            minh = math.max(minh, req_h)
          end
          local parent = sel.parent
          local px, py = 0, 0
          if parent then px = parent.x or 0; py = parent.y or 0 end
          local base_x = self.gui.x + px + sel.x
          local base_y = self.gui.y + py + sel.y
          local nw = m.x - base_x
          local nh = m.y - base_y
          -- Clamp resized size so the window stays inside the canvas
          do
            local max_w = (canvas_x + canvas_w) - base_x
            local max_h = (canvas_y + canvas_h) - base_y
            if max_w and max_w < nw then nw = max_w end
            if max_h and max_h < nh then nh = max_h end
            -- Also clamp position if top/left would escape
            local min_ax = (canvas_x - self.gui.x)
            local min_ay = (canvas_y - self.gui.y)
            local cur_ax = (parent and parent.x or 0) + (sel.x or 0)
            local cur_ay = (parent and parent.y or 0) + (sel.y or 0)
            if cur_ax < min_ax then sel.x = min_ax - (parent and parent.x or 0) end
            if cur_ay < min_ay then sel.y = min_ay - (parent and parent.y or 0) end
          end
          if nw > minw then sel.w = nw end
          if nh > minh then sel.h = nh end
        else
        local target = self.selected
        -- If dragging a child inside a window, move relative to its parent
        if target and target.parent then
          local parent = target.parent
          local px, py = 0, 0
          if parent then px = parent.x or 0; py = parent.y or 0 end
          local inset = get_header_inset(parent)
          target.x = (m.x - (self.gui.x + px)) - self._offx
          target.y = (m.y - (self.gui.y + py + inset)) - self._offy
        else
          self.selected.x = (m.x - self.gui.x) - self._offx
          self.selected.y = (m.y - self.gui.y) - self._offy
        end
        -- Clamp moved component: children inside parent, roots inside canvas
        do
          local sel = self.selected
          local aw = sel.w or 0
          local ah = sel.h or 0
          if sel.parent then
            local inset = get_header_inset(sel.parent)
            local left_inset = get_left_inset(sel.parent)
            local max_x = math.max(0, ((sel.parent.w or 0) - left_inset) - aw)
            local max_y = math.max(0, ((sel.parent.h or 0) - inset) - ah)
            sel.x = math.max(0, math.min(sel.x or 0, max_x))
            sel.y = math.max(0, math.min(sel.y or 0, max_y))
          else
            local min_x = (canvas_x - self.gui.x)
            local min_y = (canvas_y - self.gui.y)
            local max_x = (canvas_x + canvas_w) - self.gui.x - aw
            local max_y = (canvas_y + canvas_h) - self.gui.y - ah
            sel.x = math.max(min_x, math.min(sel.x or 0, max_x))
            sel.y = math.max(min_y, math.min(sel.y or 0, max_y))
          end
        end
        end
          if math.abs(m.x - self._start_drag_x) > 2 or math.abs(m.y - self._start_drag_y) > 2 then
            self._last_click_was_drag = true
          end
        -- live snapping while dragging (not during resize)
        if not self.resizing then
          local nx, ny, guides = self:_compute_snapping(self.selected)
          -- Always apply snapped local coordinates (function already returns parent-local values)
          self.selected.x, self.selected.y = nx, ny
          -- Clamp after snapping too
          do
            local sel = self.selected
            local aw = sel.w or 0
            local ah = sel.h or 0
            if sel.parent then
              local inset = get_header_inset(sel.parent)
              local left_inset = get_left_inset(sel.parent)
              local max_x = math.max(0, ((sel.parent.w or 0) - left_inset) - aw)
              local max_y = math.max(0, ((sel.parent.h or 0) - inset) - ah)
              sel.x = math.max(0, math.min(sel.x or 0, max_x))
              sel.y = math.max(0, math.min(sel.y or 0, max_y))
            else
              local min_x = (canvas_x - self.gui.x)
              local min_y = (canvas_y - self.gui.y)
              local max_x = (canvas_x + canvas_w) - self.gui.x - aw
              local max_y = (canvas_y + canvas_h) - self.gui.y - ah
              sel.x = math.max(min_x, math.min(sel.x or 0, max_x))
              sel.y = math.max(min_y, math.min(sel.y or 0, max_y))
            end
          end
          self._snap_guides = guides
        else
          self._snap_guides = nil
        end
      else
        self.dragging = false
        self.resizing = false
        self.resize_corner = nil
        self._snap_guides = nil -- hide guides after release
      end
  end
  end

  -- delete selected
  if core.input and core.input.is_key_pressed and core.input.is_key_pressed(VK_DELETE) then
    if self.selected then self:_remove_component(self.selected) end
  end

  -- draw components: only root-level here; draw each parent's children relative to it
  for i = 1, #self.components do
    local c = self.components[i]
    if not c.parent then
    draw_component(c, self.gui.x + c.x, self.gui.y + c.y)
      if c.children and #c.children > 0 then
        local inset = (c.kind == "window" and get_header_inset(c)) or 0
        for j = 1, #c.children do
          local ch = c.children[j]
          draw_component(ch, self.gui.x + c.x + (ch.x or 0), self.gui.y + c.y + inset + (ch.y or 0))
        end
      end
    end
  end

  -- Right-side column: Treeview (top ~300px) + Properties below
  do
    local px = canvas_x + canvas_w + side_gap
    local col_w = 250
    -- Treeview fixed height (max 300); properties fill the remainder below
    local tree_h = math.min(300, canvas_h)
    local bg = constants.color.new(14, 18, 30, 220)
    local bd = constants.color.new(32, 40, 70, 255)
    -- Reusable Treeview component
    if not self._treeview then
      self._treeview = self.gui:AddTreeview(px - self.gui.x, canvas_y - self.gui.y, col_w, tree_h, {
        title = "Treeview",
        get_roots = function()
          local roots = {}
          for i = 1, #self.components do local c = self.components[i]; if not c.parent then table.insert(roots, c) end end
          return roots
        end,
        get_children = function(_, node) return node.children or {} end,
        get_label = function(_, node) return tostring(node.name or node.kind or "") end,
        is_container = function(_, node) return (node.children and #node.children > 0) end
      }, function(_, node) self.selected = node end)
    end
    -- keep position/size synced
    self._treeview.x = px - self.gui.x
    self._treeview.y = canvas_y - self.gui.y
    self._treeview.w = col_w
    self._treeview.h = tree_h

    -- Properties area switched to Optionbox-based layout
    local props_y = canvas_y + tree_h + 10
    local props_h = math.max(60, canvas_h - tree_h - 10)
    -- Create or update an Optionbox
    self._props_ob = self._props_ob or self.gui:AddOptionbox("Properties", px - self.gui.x, props_y - self.gui.y, col_w, props_h)
    self._props_ob.x = px - self.gui.x; self._props_ob.y = props_y - self.gui.y; self._props_ob.w = col_w; self._props_ob.h = props_h
    if self._props_ob.set_visible_if then
      self._props_ob:set_visible_if(function() return self.selected ~= nil end)
    end
    -- Build spoilers dynamically per selection (shared General + component groups)
    local need_rebuild = (self._last_selected_ref ~= self.selected) or (not self._sp_general)
    if need_rebuild then
      self._last_selected_ref = self.selected
      self._props_ob:clear()
      -- Shared General
      self._sp_general = self.gui:AddSpoiler("General", 20, 80)
      self._props_ob:add_child(self._sp_general)
      self._sp_general.is_open = true; self._sp_general.h = self._sp_general.h_expanded
      -- Component-provided groups
      self._comp_spoilers = {}
      if self.selected and self.selected.kind == "window" then
        local WindowComp = require("gui/components/window")
        local spec = WindowComp.get_properties_spec and WindowComp.get_properties_spec(self.selected)
        if spec then
          local function measure_group_height(rows)
            local h = 6
            for i = 1, #rows do
              local row = rows[i]
              if (not row.visible) or row.visible() then
                if row.type == "color" then h = h + 24
                elseif row.type == "checkbox" then h = h + 18
                elseif row.type == "number2" then h = h + 22
                elseif row.type == "combo" then h = h + 42
                elseif row.type == "separator" then h = h + 14
                else h = h + 18 end
              end
            end
            return math.max(40, h + 6)
          end
          for i = 1, #spec do
            local g = spec[i]
            local title = tostring(g.title or ("Section " .. i))
            local h_exp = measure_group_height(g.rows or {})
            local sp = self.gui:AddSpoiler(title, 20, h_exp)
            sp.is_open = (g.open ~= false)
            sp.h = sp.is_open and sp.h_expanded or sp.h_collapsed
            -- bind declarative rows to the spoiler itself so Optionbox owns rendering
            if sp.set_rows then sp:set_rows(g.rows or {}, { gui = self.gui }) end
            self._props_ob:add_child(sp)
            table.insert(self._comp_spoilers, sp)
          end
        end
      elseif self.selected and self.selected.kind == "colorpicker" then
        local CP = require("gui/components/color_picker")
        local spec = CP.get_properties_spec and CP.get_properties_spec(self.selected)
        if spec then
          local function measure_group_height(rows)
            local h = 6
            for i = 1, #rows do
              local row = rows[i]
              if (not row.visible) or row.visible() then
                if row.type == "color" then h = h + 24
                elseif row.type == "checkbox" then h = h + 18
                elseif row.type == "number2" then h = h + 22
                elseif row.type == "combo" then h = h + 42
                elseif row.type == "separator" then h = h + 14
                elseif row.type == "text" then h = h + 22
                else h = h + 18 end
              end
            end
            return math.max(40, h + 6)
          end
          for i = 1, #spec do
            local g = spec[i]
            local title = tostring(g.title or ("Section " .. i))
            local h_exp = measure_group_height(g.rows or {})
            local sp = self.gui:AddSpoiler(title, 20, h_exp)
            sp.is_open = (g.open ~= false)
            sp.h = sp.is_open and sp.h_expanded or sp.h_collapsed
            if sp.set_rows then sp:set_rows(g.rows or {}, { gui = self.gui }) end
            self._props_ob:add_child(sp)
            table.insert(self._comp_spoilers, sp)
          end
        end
      end
      if self._props_ob and self._props_ob._layout_children then self._props_ob:_layout_children() end
    end
    -- helpers to place rows inside a spoiler body
    local function spoiler_body_top(sp)
      local ob = self._props_ob
      local ob_abs_y = self.gui.y + ob.y
      local top = ob_abs_y + (sp.y or 0) + 20 - (ob.scroll_y or 0)
      local abs_x = self.gui.x + ob.x
      return abs_x, top
    end
    local label_col = function() return constants.color.white(230) end
    local row_x_pad = 10
    local inner_w = (self._props_ob and (self._props_ob.w - 12)) or col_w
    -- Draw General fields into Optionbox
    if self.selected then
      local bx, by = spoiler_body_top(self._sp_general)
      local base_x = bx + row_x_pad
      local y = by + 6
      if self._sp_general and self._sp_general.is_open then
        -- Name
        local label = "Name:"
        local label_fs = 13
        local label_ty = y + math.floor((20 - label_fs) / 2) - 1
        core.graphics.text_2d(label, constants.vec2.new(base_x, label_ty), label_fs, label_col(), false)
        local lw = (core.graphics.get_text_width and core.graphics.get_text_width(label, label_fs, 0)) or 42
        local input_x = base_x + lw + 6
        local input_w = inner_w - lw - 26
        if not self._props_name_input then
          self._props_name_input = self.gui:AddInput(input_x - self.gui.x, y - self.gui.y, input_w, 20, { multiline = false, text = tostring(self.selected.name or "") }, function(_, val)
            local ok = true
            local v = tostring(val or "")
            if v == "" then ok = false end
            for i = 1, #self.components do local c2 = self.components[i]; if c2 ~= self.selected and c2.name == v then ok = false break end end
            self._prop_name_valid = ok
          end)
          self._props_name_input:set_visible_if(function() return self.selected ~= nil and self._sp_general and self._sp_general.is_open end)
        end
        self._props_name_input.x = input_x - self.gui.x; self._props_name_input.y = y - self.gui.y; self._props_name_input.w = input_w
        -- Rebind visibility each frame to avoid stale closures after reloads
        if self._props_name_input.set_visible_if then
          self._props_name_input:set_visible_if(function() return self.selected ~= nil and self._sp_general and self._sp_general.is_open end)
        end
        local cur_name = tostring(self.selected.name or "")
        if self._props_name_input:get_text() ~= cur_name and not self._props_name_input.is_focused then self._props_name_input:set_text(cur_name) end
        local name_col = self._prop_name_valid and constants.color.white(235) or constants.color.new(230, 80, 80, 255)
        core.graphics.rect_2d(constants.vec2.new(input_x, y), input_w, 20, name_col, 1, 4)
        y = y + 24
        -- Title moved to component-owned Header category; no Title here
        -- Update General spoiler height to match used space
        do
          local used_h = (y - by) + 6 + 20 -- body + bottom pad + header
          local min_h = self._sp_general.h_collapsed or 24
          local gh = math.max(min_h, used_h)
          self._sp_general.h_expanded = gh
          self._sp_general.h = gh
          if self._props_ob and self._props_ob._layout_children then self._props_ob:_layout_children() end
        end
      end
      -- Component-provided groups rendering
      if self.selected.kind == "window" and self._comp_spoilers then
        local WindowComp = require("gui/components/window")
        local spec = WindowComp.get_properties_spec and WindowComp.get_properties_spec(self.selected)
        if spec then
          for gi = 1, #spec do
            local sp = self._comp_spoilers[gi]
            if sp and sp.is_open and sp.measure_rows then
              sp.h_expanded = sp:measure_rows()
              sp.h = sp.h_expanded
            end
          end
          if self._props_ob and self._props_ob._layout_children then self._props_ob:_layout_children() end
        end
      end
      -- Component-specific properties for ColorPicker
      if self.selected.kind == "colorpicker" and self._comp_spoilers == nil then
        local CP = require("gui/components/color_picker")
        local cps = CP.get_properties_spec and CP.get_properties_spec(self.selected)
        if cps then
          self._comp_spoilers = {}
          for i = 1, #cps do
            local g = cps[i]
            local sp = self.gui:AddSpoiler(tostring(g.title or ("Section "..i)), 20, 60)
            if sp.set_rows then sp:set_rows(g.rows or {}, { gui = self.gui }) end
            sp.is_open = (g.open ~= false)
            sp.h = sp.is_open and sp.h_expanded or sp.h_collapsed
            self._props_ob:add_child(sp)
            table.insert(self._comp_spoilers, sp)
          end
          if self._props_ob and self._props_ob._layout_children then self._props_ob:_layout_children() end
        end
      end
      -- Keep ColorPicker group heights fresh as rows toggle visibility
      if self.selected.kind == "colorpicker" and self._comp_spoilers then
        for i = 1, #self._comp_spoilers do
          local sp = self._comp_spoilers[i]
          if sp and sp.is_open and sp.measure_rows then
            sp.h_expanded = sp:measure_rows()
            sp.h = sp.h_expanded
          end
        end
        if self._props_ob and self._props_ob._layout_children then self._props_ob:_layout_children() end
      end
      -- Global animations section removed; animations belong to component groups
    else
      -- Nothing selected → draw hint in Optionbox background
      local hint = "Select an element to edit its properties"
      local tw = (core.graphics.get_text_width and core.graphics.get_text_width(hint, 12, 0)) or 180
      local hx = px + math.floor((col_w - tw) / 2)
      local hy = props_y + 40
      core.graphics.text_2d(hint, constants.vec2.new(hx, hy), 12, constants.color.white(150), false)
    end
  end

  -- Draw snapping guides while dragging
  if self._snap_guides then
    local accent = constants.color.new(120, 190, 255, 220)
    if self._snap_guides.v and self._snap_guides.v.x then
      local xg = self._snap_guides.v.x
      core.graphics.line_2d(constants.vec2.new(xg, canvas_y), constants.vec2.new(xg, canvas_y + canvas_h), accent, 1)
      -- draw small center marker
      core.graphics.rect_2d_filled(constants.vec2.new(xg - 2, canvas_y + math.floor(canvas_h/2) - 2), 4, 4, accent, 1)
    end
    if self._snap_guides.h and self._snap_guides.h.y then
      local yg = self._snap_guides.h.y
      core.graphics.line_2d(constants.vec2.new(canvas_x, yg), constants.vec2.new(canvas_x + canvas_w, yg), accent, 1)
      -- draw small center marker
      core.graphics.rect_2d_filled(constants.vec2.new(canvas_x + math.floor(canvas_w/2) - 2, yg - 2), 4, 4, accent, 1)
    end
  end

  -- draw toast/hint if any
  if (core.time() or 0) < (self._toast_until or 0) and self._toast_text then
    local tx = self._toast_x or (canvas_x + 12)
    local ty = self._toast_y or (canvas_y + 12)
    local pad = 6
    local txt = self._toast_text
    local tw = (core.graphics.get_text_width and core.graphics.get_text_width(txt, constants.FONT_SIZE, 0)) or 120
    local bg = constants.color.new(16, 20, 34, 240)
    local bd = constants.color.new(32, 40, 70, 255)
    core.graphics.rect_2d_filled(constants.vec2.new(tx, ty), tw + pad*2, 20, bg, 6)
    core.graphics.rect_2d(constants.vec2.new(tx, ty), tw + pad*2, 20, bd, 1, 6)
    core.graphics.text_2d(txt, constants.vec2.new(tx + pad, ty + 2), constants.FONT_SIZE, constants.color.white(235), false)
  end

  -- Keep inline editor positioned/sized over its target while active
  if self._inline_edit_active and self._inline_input and self._inline_target then
    local t = self._inline_target
    -- Overlay the component bounds to make clicking anywhere keep focus
    local px = (t.parent and t.parent.x) or 0
    local py = (t.parent and t.parent.y) or 0
    self._inline_input.x = px + t.x
    self._inline_input.y = py + t.y
    self._inline_input.w = t.w
    self._inline_input.h = t.h
  end

  -- Context menu rendering (on top)
  if self._ctx_open and self._ctx_target then
    local cm_x = self._ctx_x
    local cm_y = self._ctx_y
    local cm_w = 160
    local row_h = 18
    local items = { "Delete" }
    local bg = constants.color.new(16, 20, 34, 240)
    local bd = constants.color.new(32, 40, 70, 255)
    core.graphics.rect_2d_filled(constants.vec2.new(cm_x, cm_y), cm_w, row_h * #items + 8, bg, 6)
    core.graphics.rect_2d(constants.vec2.new(cm_x, cm_y), cm_w, row_h * #items + 8, bd, 1, 6)
    local my = cm_y + 4
    local mx = m.x
    local mypos = m.y
    for i = 1, #items do
      local over = point_in_rect(mx, mypos, cm_x + 2, my, cm_w - 4, row_h)
      local fill = over and constants.color.new(56, 88, 150, 240) or constants.color.new(26, 32, 48, 220)
      core.graphics.rect_2d_filled(constants.vec2.new(cm_x + 2, my), cm_w - 4, row_h, fill, 4)
      core.graphics.text_2d(items[i], constants.vec2.new(cm_x + 8, my - 1), constants.FONT_SIZE, constants.color.white(255), false)
      if over and constants.mouse_state.left_clicked then
        local act = items[i]
        if act == "Delete" then
          self:_remove_component(self._ctx_target)
        end
      end
      my = my + row_h
    end
    -- close on click outside
    if not point_in_rect(mx, mypos, cm_x, cm_y, cm_w, row_h * #items + 8) and constants.mouse_state.left_clicked then
      self._ctx_open = false
    end
  end

  -- Inline Edit pill removed; edit is accessible from the context menu only

  -- Properties popup (simple controls)
  if self._edit_props_popup and self.selected then
    local ex = self._props_x or (canvas_x + 8)
    local ey = self._props_y or (canvas_y + 30)
    local pw = 220
    local ph = 128
    local bg = constants.color.new(16, 20, 34, 240)
    local bd = constants.color.new(32, 40, 70, 255)
    core.graphics.rect_2d_filled(constants.vec2.new(ex, ey), pw, ph, bg, 6)
    core.graphics.rect_2d(constants.vec2.new(ex, ey), pw, ph, bd, 1, 6)
    local y = ey + 6
    core.graphics.text_2d("Properties", constants.vec2.new(ex + 8, y), constants.FONT_SIZE, constants.color.white(255), false)
    y = y + 18
    -- Text input field for text-capable components
    local k = self.selected.kind
    if k == "label" or k == "button" or k == "checkbox" or k == "combobox" or k == "panel" then
      core.graphics.text_2d("Text", constants.vec2.new(ex + 8, y), constants.FONT_SIZE, constants.color.white(255), false)
      local input_x = ex + 60
      local input_w = pw - 68
      -- create once
      if not self._props_text_input then
        self._props_text_input = self.gui:AddInput(input_x - self.gui.x, y - self.gui.y, input_w, 20, { multiline = false, text = tostring(self.selected.text or self.selected.title or "") }, function(_, val)
          if k == "panel" then self.selected.title = val else self.selected.text = val end
        end)
        self._props_text_input:set_visible_if(function() return self._edit_props_popup and self.selected ~= nil end)
      end
      -- keep synced/positioned
      self._props_text_input.x = input_x - self.gui.x
      self._props_text_input.y = y - self.gui.y
      self._props_text_input.w = input_w
      local cur_disp = tostring(self.selected.text or self.selected.title or "")
      if self._props_text_input:get_text() ~= cur_disp then
        self._props_text_input:set_text(cur_disp)
      end
      y = y + 26
    end
    -- Resizing moved to corner handle; no width/height steppers in edit
    -- close button
    local cx, cy, cw, ch = ex + pw - 48, ey + ph - 22, 40, 18
    core.graphics.rect_2d_filled(constants.vec2.new(cx, cy), cw, ch, constants.color.new(86,120,200,230), 4)
    core.graphics.text_2d("Close", constants.vec2.new(cx + 8, cy - 2), constants.FONT_SIZE, constants.color.white(255), false)
    if point_in_rect(m.x, m.y, cx, cy, cw, ch) and constants.mouse_state.left_clicked then
      self._edit_props_popup = false
    end
    -- close if click outside
    if not self._props_just_opened and constants.mouse_state.left_clicked and not point_in_rect(m.x, m.y, ex, ey, pw, ph) then
      self._edit_props_popup = false
    end
    -- debounce: only for the first frame after opening
    if self._props_just_opened then self._props_just_opened = false end
  end

  -- Close inline edit when it loses focus or when user clicks elsewhere
  if self._inline_edit_active and self._inline_input then
    if not self._inline_just_opened and not self._inline_input.is_focused then
      self._inline_edit_active = false
    end
    if self._inline_just_opened then self._inline_just_opened = false end
  end

  -- When inline edit deactivates, clear editing flag on target
  if (not self._inline_edit_active) and self._inline_target and self._inline_target.__editing then
    self._inline_target.__editing = nil
    self._inline_target = nil
  end

  -- Export button moved to palette panel (see above)
end

local function escape_str(s)
  s = tostring(s or "")
  s = s:gsub("\\", "\\\\"):gsub("\"", "\\\"")
  return s
end

function Designer:export()
  if not core.create_data_folder or not core.create_data_file or not core.write_data_file then return end
  core.create_data_folder("Lx_UI")
  core.create_data_folder("Lx_UI/exports")
  local fname = "Lx_UI/exports/ui_" .. tostring(core.time() or 0) .. ".lua"
  local lines = {}
  table.insert(lines, "local M = {}\n")
  table.insert(lines, "function M.init()\n")
  table.insert(lines, "  local UI = _G.Lx_UI\n")
  table.insert(lines, "  if not UI then return end\n")
  table.insert(lines, "  local gui = UI.register(\"Exported UI\", 600, 400, \"exported_ui\")\n")
  table.insert(lines, "  gui.is_open = true\n")
  -- emit creation calls
  local btn_index = 0
  for i = 1, #self.components do
    local c = self.components[i]
    local k = c.kind
    if k == "label" then
      table.insert(lines, string.format("  gui:AddLabel(\"%s\", %d, %d)\n", escape_str(c.text or "Label"), c.x, c.y))
    elseif k == "button" then
      btn_index = btn_index + 1
      local handler = "onClick_" .. tostring(btn_index)
      table.insert(lines, string.format("  gui:AddButton(\"%s\", %d, %d, %d, %d, function() if M.handlers and M.handlers.%s then M.handlers.%s() end end)\n", escape_str(c.text or "Button"), c.x, c.y, c.w, c.h, handler, handler))
    elseif k == "checkbox" then
      table.insert(lines, string.format("  gui:AddCheckbox(\"%s\", %d, %d, false, function() end)\n", escape_str(c.text or "Checkbox"), c.x, c.y))
    elseif k == "combobox" then
      table.insert(lines, string.format("  gui:AddLabel(\"%s\", %d, %d) -- placeholder for combobox\n", escape_str(c.text or "Combobox"), c.x, c.y))
    elseif k == "slider" then
      table.insert(lines, string.format("  gui:AddLabel(\"Slider\", %d, %d) -- add slider via Menu:AddSlider if needed\n", c.x, c.y))
    elseif k == "listbox" then
      table.insert(lines, string.format("  gui:AddLabel(\"Listbox\", %d, %d) -- add listbox via Menu:AddListbox if needed\n", c.x, c.y))
    elseif k == "panel" then
      table.insert(lines, string.format("  gui:AddPanel(\"%s\", %d, %d, %d, %d)\n", escape_str(c.title or "Panel"), c.x, c.y, c.w, c.h))
    end
  end
  table.insert(lines, "end\n\n")
  table.insert(lines, "M.handlers = {}\n\nreturn M\n")
  local content = table.concat(lines)
  core.create_data_file(fname)
  core.write_data_file(fname, content)
  core.log("[Lx_UI] Exported UI to data file: " .. fname)
end

return {
  new = function(owner_gui) return Designer:new(owner_gui) end
}


