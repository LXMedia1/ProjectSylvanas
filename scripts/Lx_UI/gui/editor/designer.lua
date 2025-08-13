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
    { id = "keybind",  name = "Keybind",  w = 200, h = 22,  cat = "Inputs" },
    { id = "toggle",   name = "Toggle",   w = 46,  h = 22,  cat = "Inputs" },
    { id = "radio",    name = "RadioGroup", w = 160, h = 48, cat = "Inputs" },
    { id = "progress", name = "ProgressBar", w = 200, h = 14, cat = "Basic" },
    { id = "separator",name = "Separator", w = 200, h = 1,  cat = "Basic" },
  { id = "window",   name = "Window",   w = 320, h = 220, cat = "Containers" },
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
  return o
end
-- Snap helper: align component to neighbors when close (vertical stack and left-edge align)
function Designer:_compute_snapping(comp)
  if not self.snap_enabled or not comp then return comp.x, comp.y, nil end
  -- effective position helpers (gui-local, including parent offsets)
  local function eff_xy(c)
    local x, y = (c.x or 0), (c.y or 0)
    local p = c.parent
    while p do
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
  return kind == "window" or kind == "panel" or kind == "scroll"
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
  elseif k == "window" then
    local function to_col(c)
      if type(c) == "table" then return constants.color.new(c.r or 0, c.g or 0, c.b or 0, c.a or 255) end
      return c
    end
    local style = comp.style or "window"
    local border = to_col(comp.border_col or { r = 32, g = 40, b = 70, a = 255 })
    if style == "window" then
      local hb = to_col(comp.header_col or { r = 56, g = 80, b = 140, a = 230 })
      local bg = to_col(comp.bg_col or { r = 14, g = 18, b = 30, a = 220 })
      core.graphics.rect_2d_filled(constants.vec2.new(x, y), w, h, bg, 6)
      core.graphics.rect_2d(constants.vec2.new(x, y), w, h, border, 1, 6)
      core.graphics.rect_2d_filled(constants.vec2.new(x, y), w, 20, hb, 6)
      local tc = to_col(comp.title_col or { r = 240, g = 240, b = 245, a = 255 })
      core.graphics.text_2d(comp.title or comp.name or "Window", constants.vec2.new(x + 8, y + 2), constants.FONT_SIZE, tc, false)
      local hint = "(drop items here)"
      core.graphics.text_2d(hint, constants.vec2.new(x + 8, y + 26), 12, constants.color.white(120), false)
    elseif style == "box" then
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
        -- Enforce: non-container components must be dropped inside a parent
        local new_kind = self._palette_drag_kind
        if (not parent) and (not is_container_kind(new_kind)) then
          -- do not create; show a brief pulsing warning label component
          if self.gui and self.gui.AddWarning then
            local msg = "Drop inside a parent (Window/Panel/Scroll)"
            local wx = m.x - self.gui.x + 12
            local wy = m.y - self.gui.y + 12
            self.gui:AddWarning(msg, wx, wy, 1400)
          else
            -- fallback toast (unlikely)
            self._toast_text = "Drop inside a parent (Window/Panel/Scroll)"
            self._toast_until = (core.time() or 0) + 1400
            self._toast_x, self._toast_y = m.x + 12, m.y + 12
          end
        else
          -- clamp to canvas bounds
        cx = math.max(0, math.min(cx, (canvas_x + canvas_w) - self.gui.x - (def and def.w or self._drag_w)))
        cy = math.max(0, math.min(cy, (canvas_y + canvas_h) - self.gui.y - (def and def.h or self._drag_h)))
          self:add_component(new_kind, cx, cy)
          if parent and new_kind ~= "window" then
            local child = self.selected
            -- Convert position to parent's local coordinates
            child.x = (child.x or 0) - (parent.x or 0)
            child.y = (child.y or 0) - (parent.y or 0)
            child.parent = parent
            parent.children = parent.children or {}
            table.insert(parent.children, child)
          end
          local nx, ny = self:_compute_snapping(self.selected)
          if self.selected then
            self.selected.x, self.selected.y = nx, ny
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
      local cx, cy = self.gui.x + parent_offset_x + c.x, self.gui.y + parent_offset_y + c.y
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
          local minw, minh = 60, 60
          local parent = sel.parent
          local px, py = 0, 0
          if parent then px = parent.x or 0; py = parent.y or 0 end
          local base_x = self.gui.x + px + sel.x
          local base_y = self.gui.y + py + sel.y
          local nw = m.x - base_x
          local nh = m.y - base_y
          if nw > minw then sel.w = nw end
          if nh > minh then sel.h = nh end
        else
        local target = self.selected
        -- If dragging a child inside a window, move relative to its parent
        if target and target.parent then
          local parent = target.parent
          local px, py = 0, 0
          if parent then px = parent.x or 0; py = parent.y or 0 end
          target.x = (m.x - (self.gui.x + px)) - self._offx
          target.y = (m.y - (self.gui.y + py)) - self._offy
        else
          self.selected.x = (m.x - self.gui.x) - self._offx
          self.selected.y = (m.y - self.gui.y) - self._offy
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
    if self.selected then
      for i = #self.components, 1, -1 do
        if self.components[i] == self.selected then table.remove(self.components, i) break end
      end
      self.selected = nil
    end
  end

  -- draw components: only root-level here; draw each parent's children relative to it
  for i = 1, #self.components do
    local c = self.components[i]
    if not c.parent then
      draw_component(c, self.gui.x + c.x, self.gui.y + c.y)
      if c.children and #c.children > 0 then
        for j = 1, #c.children do
          local ch = c.children[j]
          draw_component(ch, self.gui.x + c.x + (ch.x or 0), self.gui.y + c.y + (ch.y or 0))
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

    -- Properties panel below treeview, filling remaining space
    local props_y = canvas_y + tree_h + 10
    local props_h = math.max(60, canvas_h - tree_h - 10)
    core.graphics.rect_2d_filled(constants.vec2.new(px, props_y), col_w, props_h, bg, 6)
    core.graphics.rect_2d(constants.vec2.new(px, props_y), col_w, props_h, bd, 1, 6)
    core.graphics.text_2d("Properties", constants.vec2.new(px + 10, props_y + 6), constants.FONT_SIZE, constants.color.white(240), false)
    local y = props_y + 26
    -- Label/value rows (checkbox rows)
    local function row(label, value, on_toggle)
      core.graphics.text_2d(label, constants.vec2.new(px + 8, y), 12, constants.color.white(230), false)
      y = y + 16
      if on_toggle ~= nil then
        local cb = { x = px + 8, y = y, s = 12 }
        core.graphics.rect_2d(constants.vec2.new(cb.x, cb.y), cb.s, cb.s, bd, 1, 2)
        if value then core.graphics.rect_2d_filled(constants.vec2.new(cb.x + 2, cb.y + 2), cb.s - 4, cb.s - 4, constants.color.new(120,190,255,255), 2) end
        if point_in_rect(constants.mouse_state.position.x, constants.mouse_state.position.y, cb.x, cb.y, cb.s + 140, cb.s) and constants.mouse_state.left_clicked then
          on_toggle(not value)
        end
        y = y + 18
      end
    end
    if self.selected then
      -- Name (UID) field
      -- Inline label + input: Name: [........]
      local label = "Name:"
      local lw = (core.graphics.get_text_width and core.graphics.get_text_width(label, 12, 0)) or 42
      core.graphics.text_2d(label, constants.vec2.new(px + 10, y), 12, constants.color.white(235), false)
      local input_x = px + 10 + lw + 6
      local input_w = col_w - lw - 16
      if not self._props_name_input then
        self._props_name_input = self.gui:AddInput(input_x - self.gui.x, y - self.gui.y, input_w, 20, { multiline = false, text = tostring(self.selected.name or "") }, function(_, val)
          -- live validate
          local ok = true
          local v = tostring(val or "")
          if v == "" then ok = false end
          for i = 1, #self.components do
            local c2 = self.components[i]
            if c2 ~= self.selected and c2.name == v then ok = false break end
          end
          self._prop_name_valid = ok
        end)
        self._props_name_input:set_visible_if(function() return self.selected ~= nil end)
      end
      -- sync & position
      self._props_name_input.x = input_x - self.gui.x
      self._props_name_input.y = y - self.gui.y
      self._props_name_input.w = input_w
      local cur_name = tostring(self.selected.name or "")
      if self._props_name_input:get_text() ~= cur_name and not self._props_name_input.is_focused then
        self._props_name_input:set_text(cur_name)
      end
      -- color feedback (border/underline)
      local name_col = self._prop_name_valid and constants.color.white(235) or constants.color.new(230, 80, 80, 255)
      core.graphics.rect_2d(constants.vec2.new(input_x, y), input_w, 20, name_col, 1, 4)
      -- commit on Enter if valid; show success flash
      if self._props_name_input.is_focused then
        local VK_RETURN = 0x0D
        if core.input.is_key_pressed and core.input.is_key_pressed(VK_RETURN) and self._prop_name_valid then
          self.selected.name = self._props_name_input:get_text()
          self._prop_name_commit_until = (core.time() or 0) + 1000
          self._props_name_input.is_focused = false
        end
      end
      -- success tick display
      if (core.time() or 0) < (self._prop_name_commit_until or 0) then
        local tick_col = constants.color.new(120, 220, 140, 255)
        local tx = input_x + input_w - 14
        local ty = y + 5
        core.graphics.line_2d(constants.vec2.new(tx + 0, ty + 6), constants.vec2.new(tx + 4, ty + 10), tick_col, 2)
        core.graphics.line_2d(constants.vec2.new(tx + 4, ty + 10), constants.vec2.new(tx + 12, ty + 0), tick_col, 2)
      elseif not self._prop_name_valid then
        local x_col = constants.color.new(230, 80, 80, 255)
        local cx = input_x + input_w - 12
        local cy = y + 4
        core.graphics.line_2d(constants.vec2.new(cx, cy), constants.vec2.new(cx + 8, cy + 8), x_col, 2)
        core.graphics.line_2d(constants.vec2.new(cx + 8, cy), constants.vec2.new(cx, cy + 8), x_col, 2)
      end
      y = y + 26

      -- Text (drawn string) field when applicable
      local tlabel = "Title:"
      local tlw = (core.graphics.get_text_width and core.graphics.get_text_width(tlabel, 12, 0)) or 46
      core.graphics.text_2d(tlabel, constants.vec2.new(px + 10, y), 12, constants.color.white(235), false)
      local text_x = px + 10 + tlw + 6
      local text_w = col_w - tlw - 16
      if not self._props_text_input then
        local initial_text
        if self.selected.kind == "panel" or self.selected.kind == "window" then
          initial_text = tostring(self.selected.title or "")
        else
          initial_text = tostring(self.selected.text or "")
        end
        self._props_text_input = self.gui:AddInput(text_x - self.gui.x, y - self.gui.y, text_w, 20, { multiline = false, text = initial_text }, function(_, val)
          if self.selected then
            if self.selected.kind == "panel" or self.selected.kind == "window" then
              self.selected.title = val
            else
              self.selected.text = val
            end
          end
        end)
        self._props_text_input:set_visible_if(function() return self.selected ~= nil end)
      end
      self._props_text_input.x = text_x - self.gui.x
      self._props_text_input.y = y - self.gui.y
      self._props_text_input.w = text_w
      do
        local cur_disp
        if self.selected.kind == "panel" or self.selected.kind == "window" then
          cur_disp = tostring(self.selected.title or "")
        else
          cur_disp = tostring(self.selected.text or "")
        end
        -- Keep user edits while focused; when not focused, sync to the selected component
        if self._props_text_input.is_focused then
          local val = self._props_text_input:get_text()
          if self.selected then
            if self.selected.kind == "panel" or self.selected.kind == "window" then
              self.selected.title = val
            else
              self.selected.text = val
            end
          end
        else
          if self._props_text_input:get_text() ~= cur_disp then
            self._props_text_input:set_text(cur_disp)
          end
        end
      end
      core.graphics.rect_2d(constants.vec2.new(text_x, y), text_w, 20, constants.color.white(50), 1, 4)
      y = y + 26

      -- Professional separators and future options
      core.graphics.rect_2d(constants.vec2.new(px + 10, y), col_w - 20, 1, constants.color.new(40, 48, 72, 200), 1, 0)
      y = y + 10
      -- (Bold/Underline removed)
      if self.selected.kind == "window" then
        local WindowComp = require("gui/components/window")
        if WindowComp and WindowComp.draw_designer_properties then
          y = WindowComp.draw_designer_properties(self, px, y, col_w, self.selected)
        end
      end
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
    local items = { "Edit", "Bring to front", "Duplicate", "Delete" }
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
        if act == "Edit" then
          -- open properties popup near the cursor
          self._edit_props_popup = true
          self._props_x, self._props_y = cm_x + cm_w + 6, cm_y
          self._props_just_opened = true
          self._ctx_open = false
        elseif act == "Resize" then
          -- toggle resize mode; resizing works by dragging the corner handles
          self._resize_mode = not not (not self._resize_mode)
          self._ctx_open = false
        elseif act == "Bring to front" then
          -- move target to end of array
          local t = self._ctx_target
          for idx = 1, #self.components do
            if self.components[idx] == t then table.remove(self.components, idx) break end
          end
          table.insert(self.components, t)
          self._ctx_open = false
        elseif act == "Duplicate" then
          local t = self._ctx_target
          local copy = { kind = t.kind, x = t.x + 10, y = t.y + 10, w = t.w, h = t.h, text = t.text, title = t.title }
          table.insert(self.components, copy)
          self.selected = copy
          self._ctx_open = false
        elseif act == "Delete" then
          local t = self._ctx_target
          for idx = #self.components, 1, -1 do
            if self.components[idx] == t then table.remove(self.components, idx) break end
          end
          self.selected = nil
          self._ctx_open = false
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


