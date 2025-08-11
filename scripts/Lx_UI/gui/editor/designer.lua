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
  return o
end

local function point_in_rect(px, py, x, y, w, h)
  return px >= x and px <= x + w and py >= y and py <= y + h
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
    if over and constants.mouse_state.left_clicked then self.active_tool = d.id end
    px = px + bw + 6
  end

  -- Canvas background
  core.graphics.rect_2d_filled(constants.vec2.new(canvas_x, canvas_y), canvas_w, canvas_h, constants.color.new(10, 12, 18, 160), 6)
  core.graphics.rect_2d(constants.vec2.new(canvas_x, canvas_y), canvas_w, canvas_h, constants.color.new(32,40,70,255), 1, 6)

  -- Add component on click in empty area
  local m = constants.mouse_state.position
  if constants.mouse_state.left_clicked and point_in_rect(m.x, m.y, canvas_x, canvas_y, canvas_w, canvas_h) then
    local hit = false
    for i = #self.components, 1, -1 do
      local c = self.components[i]
      if point_in_rect(m.x, m.y, self.gui.x + c.x, self.gui.y + c.y, c.w, c.h) then hit = true break end
    end
    if not hit then
      local cx = m.x - self.gui.x
      local cy = m.y - self.gui.y
      self:add_component(self.active_tool, cx, cy)
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
      if constants.mouse_state.left_down then
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
  if point_in_rect(m.x, m.y, ex_x, ex_y, bw, bh) and constants.mouse_state.left_clicked then
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


