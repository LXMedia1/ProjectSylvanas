local constants = require("gui/utils/constants")

local Window = {}
Window.__index = Window

function Window:new(owner_gui, title, x, y, w, h)
  local o = setmetatable({}, Window)
  o.gui = owner_gui -- if set, we're a simulated child of the canvas/gui
  o.title = tostring(title or "Window")
  o.x = tonumber(x or 0) or 0
  o.y = tonumber(y or 0) or 0
  o.w = tonumber(w or 320) or 320
  o.h = tonumber(h or 220) or 220
  o.header_h = 20
  o.visible_if = nil
  o.kind = "window"
  o.is_container = true
  o.parent = nil -- windows are never real children; kept for API symmetry
  o.children = {}
  -- styling & behavior
  o.style = "window" -- window | box | invisible
  o.bg_col = { r = 14, g = 18, b = 30, a = 220 }
  o.border_col = { r = 32, g = 40, b = 70, a = 255 }
  o.header_col = { r = 56, g = 80, b = 140, a = 230 }
  o.allow_maximize = false
  o.block_clicks = false
  o.block_only_children = true -- only relevant for invisible style
  -- start position (used by consumer at spawn time)
  o.start_center = true
  o.start_x = 0
  o.start_y = 0
  return o
end

function Window:set_visible_if(fn) self.visible_if = fn end
function Window:is_visible() if self.visible_if then return not not self.visible_if(self) end return true end

function Window:_get_origin()
  if self.gui then
    return self.gui.x + self.x, self.gui.y + self.y
  end
  return self.x, self.y
end

function Window:attach_to(gui)
  if self.gui == gui then return end
  if self.gui and self.gui._windows then
    for i = #self.gui._windows, 1, -1 do
      if self.gui._windows[i] == self then table.remove(self.gui._windows, i) break end
    end
  end
  self.gui = gui
  if gui then
    gui._windows = gui._windows or {}
    table.insert(gui._windows, self)
  end
end

function Window:detach()
  self:attach_to(nil)
end

local function _col(c)
  return constants.color.new(c.r or 0, c.g or 0, c.b or 0, c.a or 255)
end

function Window:get_visible_bounds()
  -- Returns local-space bounds that should block clicks when block_clicks is true
  if self.style ~= "invisible" or (not self.block_only_children) then
    return 0, 0, self.w, self.h
  end
  -- Invisible + block only children → compute union of children rects
  local minx, miny, maxx, maxy = nil, nil, nil, nil
  for i = 1, #(self.children or {}) do
    local ch = self.children[i]
    local cx = ch.x or 0
    local cy = ch.y or 0
    local cw = ch.w or 0
    local chh = ch.h or 0
    if cw > 0 and chh > 0 then
      local r = cx + cw; local b = cy + chh
      minx = (minx and math.min(minx, cx)) or cx
      miny = (miny and math.min(miny, cy)) or cy
      maxx = (maxx and math.max(maxx, r)) or r
      maxy = (maxy and math.max(maxy, b)) or b
    end
  end
  if not minx then return nil end
  return minx, miny, (maxx - minx), (maxy - miny)
end

function Window:render()
  if self.gui and (not self.gui.is_open) then return end
  if not self:is_visible() then return end
  if not core.graphics then return end
  local gx, gy = self:_get_origin()
  local bd = _col(self.border_col)
  if self.style == "window" then
    local bg = _col(self.bg_col)
    local hb = _col(self.header_col)
    if core.graphics.rect_2d_filled then
      core.graphics.rect_2d_filled(constants.vec2.new(gx, gy), self.w, self.h, bg, 6)
      core.graphics.rect_2d_filled(constants.vec2.new(gx, gy), self.w, self.header_h, hb, 6)
    end
    if core.graphics.rect_2d then
      core.graphics.rect_2d(constants.vec2.new(gx, gy), self.w, self.h, bd, 1, 6)
    end
    if core.graphics.text_2d then
      core.graphics.text_2d(self.title, constants.vec2.new(gx + 8, gy + math.floor((self.header_h - (constants.FONT_SIZE or 14))/2) - 1), constants.FONT_SIZE, constants.color.white(255), false)
    end
  elseif self.style == "box" then
    local bg = _col(self.bg_col)
    if core.graphics.rect_2d_filled then
      core.graphics.rect_2d_filled(constants.vec2.new(gx, gy), self.w, self.h, bg, 6)
    end
    if core.graphics.rect_2d then
      core.graphics.rect_2d(constants.vec2.new(gx, gy), self.w, self.h, bd, 1, 6)
    end
  else -- invisible: draw nothing (runtime). Designer preview will show a border.
    -- no-op for runtime; consumers can still see children
  end
end

-- Optional: property helpers for Designer integration
function Window.draw_designer_properties(designer, px, y, col_w, comp)
  local bd = constants.color.new(32, 40, 70, 255)
  comp.header_h = 20 -- fixed header height for consistent styling
  comp.style = comp.style or "window"
  comp.bg_col = comp.bg_col or { r = 14, g = 18, b = 30, a = 220 }
  comp.border_col = comp.border_col or { r = 32, g = 40, b = 70, a = 255 }
  comp.header_col = comp.header_col or { r = 56, g = 80, b = 140, a = 230 }
  -- Section: Positioning
  core.graphics.text_2d("Positioning", constants.vec2.new(px + 10, y), 12, constants.color.white(230), false)
  y = y + 14
  -- size W/H inputs
  do
    core.graphics.text_2d("Size (W/H)", constants.vec2.new(px + 10, y), 12, constants.color.white(220), false)
    local ix = px + 10 + 90
    local iw = math.floor((col_w - 90 - 24) / 2)
    designer._win_size_w = designer._win_size_w or designer.gui:AddInput(ix - designer.gui.x, y - designer.gui.y, iw, 18, { multiline = false, text = tostring(comp.w or 0) }, function(_, val)
      local n = tonumber(val); if n and n > 20 then comp.w = math.floor(n) end
    end)
    designer._win_size_h = designer._win_size_h or designer.gui:AddInput(ix - designer.gui.x + iw + 8, y - designer.gui.y, iw, 18, { multiline = false, text = tostring(comp.h or 0) }, function(_, val)
      local n = tonumber(val); if n and n > 20 then comp.h = math.floor(n) end
    end)
    designer._win_size_w:set_visible_if(function() return designer.selected == comp end)
    designer._win_size_h:set_visible_if(function() return designer.selected == comp end)
    designer._win_size_w.x = ix - designer.gui.x
    designer._win_size_w.y = y - designer.gui.y
    designer._win_size_h.x = ix - designer.gui.x + iw + 8
    designer._win_size_h.y = y - designer.gui.y
    designer._win_size_w.w = iw
    designer._win_size_h.w = iw
    if not designer._win_size_w.is_focused then designer._win_size_w:set_text(tostring(comp.w or 0)) end
    if not designer._win_size_h.is_focused then designer._win_size_h:set_text(tostring(comp.h or 0)) end
    y = y + 22
  end
  -- start position
  do
    comp.start_center = (comp.start_center ~= false)
    local lbl = "Start pos: Center"
    core.graphics.text_2d(lbl, constants.vec2.new(px + 10, y), 12, constants.color.white(220), false)
    local cbx, cby, cbs = px + col_w - 20, y, 12
    core.graphics.rect_2d(constants.vec2.new(cbx, cby), cbs, cbs, bd, 1, 2)
    if comp.start_center then core.graphics.rect_2d_filled(constants.vec2.new(cbx + 2, cby + 2), cbs - 4, cbs - 4, constants.color.new(120,190,255,255), 2) end
    if constants.mouse_state.left_clicked then
      local mx, my = constants.mouse_state.position.x, constants.mouse_state.position.y
      if mx >= cbx and mx <= cbx + cbs and my >= cby and my <= cby + cbs then comp.start_center = not comp.start_center end
    end
    y = y + 18
    if not comp.start_center then
      core.graphics.text_2d("Start X/Y", constants.vec2.new(px + 10, y), 12, constants.color.white(220), false)
      local ix = px + 10 + 90
      local iw = math.floor((col_w - 90 - 24) / 2)
      designer._win_start_x = designer._win_start_x or designer.gui:AddInput(ix - designer.gui.x, y - designer.gui.y, iw, 18, { multiline = false, text = tostring(comp.start_x or 0) }, function(_, val)
        local n = tonumber(val); if n then comp.start_x = math.floor(n) end
      end)
      designer._win_start_y = designer._win_start_y or designer.gui:AddInput(ix - designer.gui.x + iw + 8, y - designer.gui.y, iw, 18, { multiline = false, text = tostring(comp.start_y or 0) }, function(_, val)
        local n = tonumber(val); if n then comp.start_y = math.floor(n) end
      end)
      designer._win_start_x:set_visible_if(function() return designer.selected == comp and not comp.start_center end)
      designer._win_start_y:set_visible_if(function() return designer.selected == comp and not comp.start_center end)
      designer._win_start_x.x = ix - designer.gui.x
      designer._win_start_x.y = y - designer.gui.y
      designer._win_start_y.x = ix - designer.gui.x + iw + 8
      designer._win_start_y.y = y - designer.gui.y
      designer._win_start_x.w = iw
      designer._win_start_y.w = iw
      if not designer._win_start_x.is_focused then designer._win_start_x:set_text(tostring(comp.start_x or 0)) end
      if not designer._win_start_y.is_focused then designer._win_start_y:set_text(tostring(comp.start_y or 0)) end
      y = y + 22
    end
  end
  -- separator
  core.graphics.rect_2d(constants.vec2.new(px + 10, y), col_w - 20, 1, constants.color.new(40, 48, 72, 200), 1, 0)
  y = y + 10
  -- Section: Styling
  core.graphics.text_2d("Styling", constants.vec2.new(px + 10, y), 12, constants.color.white(230), false)
  y = y + 14
  -- fixed header height (no stepper)
  core.graphics.text_2d("Header H", constants.vec2.new(px + 10, y), 12, constants.color.white(200), false)
  core.graphics.text_2d("20", constants.vec2.new(px + 10 + 90, y), 12, constants.color.white(220), false)
  y = y + 16
  -- color pickers
  do
    core.graphics.text_2d("Header Color", constants.vec2.new(px + 10, y), 12, constants.color.white(220), false)
    designer._win_header_cp = designer._win_header_cp or designer.gui:AddColorPicker(px + 100 - designer.gui.x, y - designer.gui.y, col_w - 110, 20, comp.header_col, function(_, c)
      comp.header_col = { r = c.r, g = c.g, b = c.b, a = c.a }
    end)
    designer._win_header_cp:set_visible_if(function() return designer.selected == comp and comp.style == "window" end)
    designer._win_header_cp.x = px + 100 - designer.gui.x
    designer._win_header_cp.y = y - designer.gui.y
    designer._win_header_cp.w = col_w - 110
    y = y + 24
    core.graphics.text_2d("Background", constants.vec2.new(px + 10, y), 12, constants.color.white(220), false)
    designer._win_bg_cp = designer._win_bg_cp or designer.gui:AddColorPicker(px + 100 - designer.gui.x, y - designer.gui.y, col_w - 110, 20, comp.bg_col, function(_, c)
      comp.bg_col = { r = c.r, g = c.g, b = c.b, a = c.a }
    end)
    designer._win_bg_cp:set_visible_if(function() return designer.selected == comp and (comp.style == "window" or comp.style == "box") end)
    designer._win_bg_cp.x = px + 100 - designer.gui.x
    designer._win_bg_cp.y = y - designer.gui.y
    designer._win_bg_cp.w = col_w - 110
    y = y + 24
  end
  -- maximize option
  do
    local lbl = "Allow maximize"
    core.graphics.text_2d(lbl, constants.vec2.new(px + 10, y), 12, constants.color.white(220), false)
    local cbx, cby, cbs = px + col_w - 20, y, 12
    core.graphics.rect_2d(constants.vec2.new(cbx, cby), cbs, cbs, bd, 1, 2)
    if comp.allow_maximize then core.graphics.rect_2d_filled(constants.vec2.new(cbx + 2, cby + 2), cbs - 4, cbs - 4, constants.color.new(120,190,255,255), 2) end
    if constants.mouse_state.left_clicked then
      local mx, my = constants.mouse_state.position.x, constants.mouse_state.position.y
      if mx >= cbx and mx <= cbx + cbs and my >= cby and my <= cby + cbs then comp.allow_maximize = not comp.allow_maximize end
    end
    y = y + 18
  end
  -- separator
  core.graphics.rect_2d(constants.vec2.new(px + 10, y), col_w - 20, 1, constants.color.new(40, 48, 72, 200), 1, 0)
  y = y + 10
  -- Section: Draw Style
  core.graphics.text_2d("Draw Style", constants.vec2.new(px + 10, y), 12, constants.color.white(230), false)
  y = y + 14
  -- style combobox
  local items = { "Window", "Box", "Invisible" }
  local idx = (comp.style == "box" and 2) or (comp.style == "invisible" and 3) or 1
  designer._win_style_cb = designer._win_style_cb or designer.gui:AddCombobox(px + 10 - designer.gui.x, y - designer.gui.y, col_w - 20, 20, items, idx, function(_, i)
    comp.style = (i == 2 and "box") or (i == 3 and "invisible") or "window"
  end, nil)
  designer._win_style_cb:set_visible_if(function() return designer.selected == comp end)
  designer._win_style_cb.x = px + 10 - designer.gui.x
  designer._win_style_cb.y = y - designer.gui.y
  designer._win_style_cb.w = col_w - 20
  -- keep selection synced
  if designer._win_style_cb.set_selected_index then
    local cur = (comp.style == "box" and 2) or (comp.style == "invisible" and 3) or 1
    if designer._win_style_cb.get_selected_index and designer._win_style_cb:get_selected_index() ~= cur then
      designer._win_style_cb:set_selected_index(cur)
    end
  end
  y = y + 24
  -- block clicks
  do
    local lbl = "Block clicks"
    core.graphics.text_2d(lbl, constants.vec2.new(px + 10, y), 12, constants.color.white(220), false)
    local cbx, cby, cbs = px + col_w - 20, y, 12
    core.graphics.rect_2d(constants.vec2.new(cbx, cby), cbs, cbs, bd, 1, 2)
    if comp.block_clicks then core.graphics.rect_2d_filled(constants.vec2.new(cbx + 2, cby + 2), cbs - 4, cbs - 4, constants.color.new(120,190,255,255), 2) end
    if constants.mouse_state.left_clicked then
      local mx, my = constants.mouse_state.position.x, constants.mouse_state.position.y
      if mx >= cbx and mx <= cbx + cbs and my >= cby and my <= cby + cbs then comp.block_clicks = not comp.block_clicks end
    end
    y = y + 18
    if comp.style == "invisible" then
      core.graphics.text_2d("Block only children", constants.vec2.new(px + 10, y), 12, constants.color.white(220), false)
      local cbx2, cby2, cbs2 = px + col_w - 20, y, 12
      core.graphics.rect_2d(constants.vec2.new(cbx2, cby2), cbs2, cbs2, bd, 1, 2)
      if comp.block_only_children then core.graphics.rect_2d_filled(constants.vec2.new(cbx2 + 2, cby2 + 2), cbs2 - 4, cbs2 - 4, constants.color.new(120,190,255,255), 2) end
      if constants.mouse_state.left_clicked then
        local mx, my = constants.mouse_state.position.x, constants.mouse_state.position.y
        if mx >= cbx2 and mx <= cbx2 + cbs2 and my >= cby2 and my <= cby2 + cbs2 then comp.block_only_children = not comp.block_only_children end
      end
      y = y + 18
    end
  end
  -- Title text color
  core.graphics.text_2d("Title Color", constants.vec2.new(px + 10, y), 12, constants.color.white(220), false)
  designer._win_title_cp = designer._win_title_cp or designer.gui:AddColorPicker(px + 100 - designer.gui.x, y - designer.gui.y, col_w - 110, 20, comp.title_col or { r = 240, g = 240, b = 245, a = 255 }, function(_, c)
    comp.title_col = { r = c.r, g = c.g, b = c.b, a = c.a }
  end)
  designer._win_title_cp:set_visible_if(function() return designer.selected == comp end)
  designer._win_title_cp.x = px + 100 - designer.gui.x
  designer._win_title_cp.y = y - designer.gui.y
  designer._win_title_cp.w = col_w - 110
  y = y + 24
  return y
end

return Window


