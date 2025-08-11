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
  { id = "panel",    name = "Panel",    w = 220, h = 160, cat = "Containers" },
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
  return o
end

local function point_in_rect(px, py, x, y, w, h)
  return px >= x and px <= x + w and py >= y and py <= y + h
end

local function get_def(kind)
  for _, d in ipairs(palette_defs) do if d.id == kind then return d end end
  return nil
end

function Designer:add_component(kind, x, y)
  local def
  for _, d in ipairs(palette_defs) do if d.id == kind then def = d break end end
  if not def then return end
  local comp = {
    kind = def.id, x = x, y = y, w = def.w, h = def.h,
    text = def.name, title = def.name, multiline = false,
  }
  table.insert(self.components, comp)
  self.selected = comp
end

local function draw_button(x, y, w, h, label)
  local col_bg = constants.color.new(36, 52, 96, 230)
  local col_border = constants.color.new(32, 40, 70, 255)
  if core.graphics.rect_2d_filled then
    core.graphics.rect_2d_filled(constants.vec2.new(x, y), w, h, col_bg, 4)
  end
  if core.graphics.rect_2d then
    core.graphics.rect_2d(constants.vec2.new(x, y), w, h, col_border, 1, 4)
  end
  if core.graphics.text_2d then
    local tx = x + math.floor((w - core.graphics.get_text_width(label, constants.FONT_SIZE, 0)) / 2)
    local ty = y + math.floor((h - constants.FONT_SIZE) / 2) - 1
    core.graphics.text_2d(label, constants.vec2.new(tx, ty), constants.FONT_SIZE, constants.color.white(255), false)
  end
end

local function draw_component(comp, x, y)
  local k = comp.kind
  local w, h = comp.w, comp.h
  if k == "label" then
    core.graphics.text_2d(comp.text or "Label", constants.vec2.new(x, y), constants.FONT_SIZE, constants.color.white(255), false)
  elseif k == "button" then
    draw_button(x, y, w, h, comp.text or "Button")
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
  end
  -- selection handle
  if comp.__selected then
    local sel = constants.color.new(200, 220, 255, 180)
    core.graphics.rect_2d(constants.vec2.new(x - 1, y - 1), w + 2, h + 2, sel, 1, 6)
    core.graphics.rect_2d_filled(constants.vec2.new(x + w - 6, y + h - 6), 8, 8, sel, 2)
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
  local palette_y = base_y
  local canvas_x, canvas_y = base_x + palette_w + 10, base_y
  local canvas_w, canvas_h = math.max(0, content_w - palette_w - 10), content_h

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
    local list_y = palette_y + 26
    local list_y_limit = palette_y + panel_h - 10
    -- Build categories map
    local cats = {}
    for i = 1, #palette_defs do
      local d = palette_defs[i]
      local c = d.cat or "Other"
      cats[c] = cats[c] or {}
      table.insert(cats[c], d)
    end
    -- Deterministic order
    local order = { "Basic", "Inputs", "Containers", "Other" }
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
        -- clamp to canvas bounds
        cx = math.max(0, math.min(cx, (canvas_x + canvas_w) - self.gui.x - (def and def.w or self._drag_w)))
        cy = math.max(0, math.min(cy, (canvas_y + canvas_h) - self.gui.y - (def and def.h or self._drag_h)))
        self:add_component(self._palette_drag_kind, cx, cy)
      end
      self._palette_dragging = false
      self._palette_drag_kind = nil
      self._drag_w = 0
      self._drag_h = 0
    end
  end

  if pressed then
    -- only selection / move / resize start (no spawn on click)
    local hit_any = false
    for i = #self.components, 1, -1 do
      local c = self.components[i]
      local cx, cy = self.gui.x + c.x, self.gui.y + c.y
      -- when resize mode is active, check corners first
      if self._resize_mode then
        local hs = 10
        local corners = {
          {id="tl", x=cx-1,       y=cy-1},
          {id="tr", x=cx+c.w-hs+1, y=cy-1},
          {id="bl", x=cx-1,       y=cy+c.h-hs+1},
          {id="br", x=cx+c.w-hs+1, y=cy+c.h-hs+1},
        }
        for _,h in ipairs(corners) do
          if point_in_rect(m.x, m.y, h.x, h.y, hs, hs) then
            self.selected = c
            self.resizing = true
            self.resize_corner = h.id
            self.dragging = false
            hit_any = true
            break
          end
        end
        if hit_any then break end
      end
      -- move/selection
      if point_in_rect(m.x, m.y, cx, cy, c.w, c.h) then
        self.selected = c
        self.dragging = true
        self.resizing = false
        self.resize_corner = nil
        self._offx = m.x - cx
        self._offy = m.y - cy
        hit_any = true
        break
      end
    end
  end

  -- Right-click context menu open
  if constants.mouse_state.right_clicked then
    self._ctx_open = false
    self._edit_size_popup = false
    self._ctx_target = nil
    for i = #self.components, 1, -1 do
      local c = self.components[i]
      local cx, cy = self.gui.x + c.x, self.gui.y + c.y
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
  if constants.mouse_state.left_clicked then
    for i = #self.components, 1, -1 do
      local c = self.components[i]
      if point_in_rect(m.x, m.y, self.gui.x + c.x, self.gui.y + c.y, c.w, c.h) then
        self.selected = c
        self.dragging = true
        self.resizing = point_in_rect(m.x, m.y, self.gui.x + c.x + c.w - 8, self.gui.y + c.y + c.h - 8, 8, 8)
        self._offx = m.x - (self.gui.x + c.x)
        self._offy = m.y - (self.gui.y + c.y)
        break
      end
    end
  end
  if self.selected then
    self.selected.__selected = true
    if self.dragging then
      if down then
        if self.resizing then
          local sel = self.selected
          local minw, minh = 20, 12
          local gx, gy = self.gui.x, self.gui.y
          local mx, my = m.x, m.y
          if self.resize_corner == "br" then
            local nw = (mx - gx) - sel.x
            local nh = (my - gy) - sel.y
            if nw > minw then sel.w = nw end
            if nh > minh then sel.h = nh end
          elseif self.resize_corner == "tr" then
            local nw = (mx - gx) - sel.x
            local nh = (sel.y + sel.h) - (my - gy)
            if nw > minw then sel.w = nw end
            if nh > minh then
              local dy = (sel.y + sel.h) - (my - gy) - sel.h
              sel.y = sel.y + dy
              sel.h = nh
            end
          elseif self.resize_corner == "bl" then
            local nw = (sel.x + sel.w) - (mx - gx)
            local nh = (my - gy) - sel.y
            if nw > minw then
              local dx = (sel.x + sel.w) - (mx - gx) - sel.w
              sel.x = sel.x + dx
              sel.w = nw
            end
            if nh > minh then sel.h = nh end
          elseif self.resize_corner == "tl" then
            local nw = (sel.x + sel.w) - (mx - gx)
            local nh = (sel.y + sel.h) - (my - gy)
            if nw > minw then
              local dx = (sel.x + sel.w) - (mx - gx) - sel.w
              sel.x = sel.x + dx
              sel.w = nw
            end
            if nh > minh then
              local dy = (sel.y + sel.h) - (my - gy) - sel.h
              sel.y = sel.y + dy
              sel.h = nh
            end
          else
            -- legacy single-handle behaviour (bottom-right)
            local nw = (mx - gx) - sel.x
            local nh = (my - gy) - sel.y
            if nw > minw then sel.w = nw end
            if nh > minh then sel.h = nh end
          end
        else
          self.selected.x = (m.x - self.gui.x) - self._offx
          self.selected.y = (m.y - self.gui.y) - self._offy
        end
      else
        self.dragging = false
        self.resizing = false
        self.resize_corner = nil
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

  -- draw components
  for i = 1, #self.components do
    local c = self.components[i]
    draw_component(c, self.gui.x + c.x, self.gui.y + c.y)
  end

  -- Context menu rendering (on top)
  if self._ctx_open and self._ctx_target then
    local cm_x = self._ctx_x
    local cm_y = self._ctx_y
    local cm_w = 160
    local row_h = 18
    local items = { "Edit", "Resize", "Bring to front", "Duplicate", "Delete" }
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
    -- Width/Height steppers
    core.graphics.text_2d("Width", constants.vec2.new(ex + 8, y), constants.FONT_SIZE, constants.color.white(255), false)
    local function draw_stepper(x, y0, value, cb)
      local bw, bh = 18, 16
      local minus_x = x
      local plus_x = x + 60
      core.graphics.rect_2d_filled(constants.vec2.new(minus_x, y0), bw, bh, constants.color.new(36,52,96,220), 4)
      core.graphics.rect_2d_filled(constants.vec2.new(plus_x, y0), bw, bh, constants.color.new(36,52,96,220), 4)
      core.graphics.text_2d("-", constants.vec2.new(minus_x + 6, y0 - 2), constants.FONT_SIZE, constants.color.white(255), false)
      core.graphics.text_2d("+", constants.vec2.new(plus_x + 5, y0 - 2), constants.FONT_SIZE, constants.color.white(255), false)
      core.graphics.text_2d(tostring(value), constants.vec2.new(x + 24, y0 - 2), constants.FONT_SIZE, constants.color.white(255), false)
      if point_in_rect(m.x, m.y, minus_x, y0, bw, bh) and constants.mouse_state.left_clicked then cb(-10) end
      if point_in_rect(m.x, m.y, plus_x, y0, bw, bh) and constants.mouse_state.left_clicked then cb(10) end
    end
    draw_stepper(ex + 60, y, self.selected.w, function(delta) self.selected.w = math.max(20, self.selected.w + delta) end)
    y = y + 22
    core.graphics.text_2d("Height", constants.vec2.new(ex + 8, y), constants.FONT_SIZE, constants.color.white(255), false)
    draw_stepper(ex + 60, y, self.selected.h, function(delta) self.selected.h = math.max(12, self.selected.h + delta) end)
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


