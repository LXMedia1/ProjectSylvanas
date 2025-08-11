local constants = require("gui/utils/constants")

local Designer = {}
Designer.__index = Designer

local VK_DELETE = 0x2E

local palette_defs = {
  { id = "label",    name = "Label",    w = 140, h = 18 },
  { id = "button",   name = "Button",   w = 120, h = 26 },
  { id = "checkbox", name = "Checkbox", w = 140, h = 20 },
  { id = "combobox", name = "Combobox", w = 160, h = 24 },
  { id = "slider",   name = "Slider",   w = 180, h = 12 },
  { id = "listbox",  name = "Listbox",  w = 180, h = 160 },
  { id = "panel",    name = "Panel",    w = 220, h = 160 },
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
    text = def.name, title = def.name,
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
  local content_w, content_h = 0, 0
  if self.gui._tabs and self.gui._tabs.get_content_size then
    content_w, content_h = self.gui._tabs:get_content_size()
  else
    content_w = self.gui.width - (ox + 16)
    content_h = self.gui.height - (oy + 16)
  end
  local toolbar_h = 36
  local palette_y = base_y + 8
  local canvas_x, canvas_y = base_x, base_y + toolbar_h
  local canvas_w, canvas_h = content_w, math.max(0, content_h - toolbar_h)

  -- Toolbar palette
  local px = base_x
  for i, d in ipairs(palette_defs) do
    local bw, bh = 90, 20
    local over = point_in_rect(constants.mouse_state.position.x, constants.mouse_state.position.y, px, palette_y, bw, bh)
    local active = (self.active_tool == d.id)
    local bg = active and constants.color.new(86,120,200,230) or constants.color.new(36,52,96,220)
    core.graphics.rect_2d_filled(constants.vec2.new(px, palette_y), bw, bh, bg, 4)
    core.graphics.rect_2d(constants.vec2.new(px, palette_y), bw, bh, constants.color.new(32,40,70,255), 1, 4)
    core.graphics.text_2d(d.name, constants.vec2.new(px + 8, palette_y - 2), constants.Font_SIZE or constants.FONT_SIZE, constants.color.white(255), false)
    if over and constants.mouse_state.left_down then self.active_tool = d.id end
    -- start drag from palette on click
    if over and constants.mouse_state.left_clicked then
      self._palette_dragging = true
      self._palette_drag_kind = d.id
      self._drag_w = d.w
      self._drag_h = d.h
    end
    px = px + bw + 6
  end

  -- Canvas background
  core.graphics.rect_2d_filled(constants.vec2.new(canvas_x, canvas_y), canvas_w, canvas_h, constants.color.new(10, 12, 18, 160), 6)
  core.graphics.rect_2d(constants.vec2.new(canvas_x, canvas_y), canvas_w, canvas_h, constants.color.new(32,40,70,255), 1, 6)

  local m = constants.mouse_state.position
  local down = constants.mouse_state.left_down
  local pressed = (down and not self._mouse_was_down)
  local released = (self._mouse_was_down and not down)
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
      if point_in_rect(m.x, m.y, cx + c.w - 10, cy + c.h - 10, 10, 10) then
        self.selected = c
        self.resizing = true
        self.dragging = false
        hit_any = true
        break
      elseif point_in_rect(m.x, m.y, cx, cy, c.w, c.h) then
        self.selected = c
        self.dragging = true
        self.resizing = false
        self._offx = m.x - cx
        self._offy = m.y - cy
        hit_any = true
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
          local nw = (m.x - self.gui.x) - self.selected.x
          local nh = (m.y - self.gui.y) - self.selected.y
          if nw > 20 then self.selected.w = nw end
          if nh > 12 then self.selected.h = nh end
        else
          self.selected.x = (m.x - self.gui.x) - self._offx
          self.selected.y = (m.y - self.gui.y) - self._offy
        end
      else
        self.dragging = false
        self.resizing = false
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

  -- Export button
  local ex_x = canvas_x + canvas_w - 120
  local ex_y = palette_y
  local bw, bh = 110, 20
  core.graphics.rect_2d_filled(constants.vec2.new(ex_x, ex_y), bw, bh, constants.color.new(86,120,200,230), 4)
  core.graphics.rect_2d(constants.vec2.new(ex_x, ex_y), bw, bh, constants.color.new(32,40,70,255), 1, 4)
  core.graphics.text_2d("Export Lua", constants.vec2.new(ex_x + 14, ex_y - 2), constants.FONT_SIZE, constants.color.white(255), false)
  if point_in_rect(m.x, m.y, ex_x, ex_y, bw, bh) and pressed then
    self:export()
  end
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


