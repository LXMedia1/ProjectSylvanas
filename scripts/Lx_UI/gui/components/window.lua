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
  o.style = "box" -- default basic box; available: box | invisible
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

-- Returns a structured properties spec for the Designer Optionbox
function Window.get_properties_spec(comp)
  comp.header_h = 20
  comp.style = comp.style or "window"
  comp.bg_col = comp.bg_col or { r = 14, g = 18, b = 30, a = 220 }
  comp.border_col = comp.border_col or { r = 32, g = 40, b = 70, a = 255 }
  comp.header_col = comp.header_col or { r = 56, g = 80, b = 140, a = 230 }
  return {
    { type = "spoiler", title = "General", open = true, rows = {
        { type = "number2", label = "Size (W/H)", get = function() return comp.w or 0, comp.h or 0 end, set = function(w, h) if w and w > 20 then comp.w = math.floor(w) end if h and h > 20 then comp.h = math.floor(h) end end },
        { type = "checkbox", label = "Start pos: Center", style = "toggle", get = function() return comp.start_center ~= false end, set = function(v) comp.start_center = not not v end },
        { type = "number2", label = "Start X/Y", visible = function() return comp.start_center == false end,
          get = function() return comp.start_x or 0, comp.start_y or 0 end, set = function(x, y) comp.start_x = math.floor(x or 0); comp.start_y = math.floor(y or 0) end },
    }},
    { type = "spoiler", title = "Header", open = true, rows = {
        { type = "text", label = "Title", get = function() return tostring(comp.title or "") end, set = function(v) comp.title = tostring(v or "") end },
        { type = "color", label = "Header Color", get = function() return comp.header_col end, set = function(c) comp.header_col = { r=c.r,g=c.g,b=c.b,a=c.a } end },
        { type = "color", label = "Title Color", get = function() return comp.title_col or { r=240,g=240,b=245,a=255 } end,
          set = function(c) comp.title_col = { r=c.r,g=c.g,b=c.b,a=c.a } end },
    }},
    { type = "spoiler", title = "Styling", open = true, rows = {
        -- Colors for window body and border
        { type = "color", label = "Background", get = function() return comp.bg_col end, set = function(c) comp.bg_col = { r=c.r,g=c.g,b=c.b,a=c.a } end },
        { type = "color", label = "Border Color", get = function() return comp.border_col end, set = function(c) comp.border_col = { r=c.r,g=c.g,b=c.b,a=c.a } end },
        { type = "separator" },
        { type = "checkbox", label = "Allow maximize", style = "toggle", get = function() return comp.allow_maximize end, set = function(v) comp.allow_maximize = not not v end },
        { type = "combo", label = "Draw Style", items = {"Box","Window","Invisible"}, get_index = function()
            return (comp.style == "window" and 2) or (comp.style == "invisible" and 3) or 1
          end,
          set_index = function(i)
            comp.style = (i == 2 and "window") or (i == 3 and "invisible") or "box"
          end },
        { type = "combo", label = "Click Blocking", items = {"Off","Full","Children only"},
          get_index = function()
            if not comp.block_clicks then return 1 end
            if comp.block_only_children then return 3 end
            return 2
          end,
          set_index = function(i)
            if i == 1 then
              comp.block_clicks = false; comp.block_only_children = false
            elseif i == 2 then
              comp.block_clicks = true; comp.block_only_children = false
            else
              comp.block_clicks = true; comp.block_only_children = true
            end
          end },
    }},
  }
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
  if self.style == "box" then
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

return Window


