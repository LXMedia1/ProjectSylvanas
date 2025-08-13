local constants = require("gui/utils/constants")

local Treeview = {}
Treeview.__index = Treeview

-- opts: { get_roots=function() return array_of_nodes end, get_children=function(node) return array end, get_label=function(node) return string end, is_container=function(node) return bool end }
function Treeview:new(owner_gui, x, y, w, h, opts, on_select)
  local o = setmetatable({}, Treeview)
  o.gui = owner_gui
  o.x, o.y, o.w, o.h = x or 0, y or 0, w or 220, h or 300
  o.opts = opts or {}
  o.on_select = on_select
  o._expanded = {}
  o.row_h = 16
  o.indent = 12
  return o
end

local function default_get_roots(self)
  return {}
end

function Treeview:_get_roots()
  local fn = self.opts.get_roots or default_get_roots
  return fn(self)
end

function Treeview:_get_children(node)
  local fn = self.opts.get_children or function(_, n) return n.children or {} end
  return fn(self, node) or {}
end

function Treeview:_get_label(node)
  local fn = self.opts.get_label or function(_, n) return tostring(n.name or n.kind or "") end
  return fn(self, node)
end

function Treeview:_is_container(node)
  local fn = self.opts.is_container or function(_, n) return n.children and #n.children > 0 end
  return not not fn(self, node)
end

function Treeview:render()
  if not (self.gui and self.gui.is_open) then return end
  if not core.graphics then return end
  local gx, gy = self.gui.x + self.x, self.gui.y + self.y
  local w, h = self.w, self.h
  -- panel
  local bg = constants.color.new(14, 18, 30, 220)
  local bd = constants.color.new(32, 40, 70, 255)
  core.graphics.rect_2d_filled(constants.vec2.new(gx, gy), w, h, bg, 6)
  core.graphics.rect_2d(constants.vec2.new(gx, gy), w, h, bd, 1, 6)
  local y = gy + 6
  if core.graphics.text_2d and self.opts.title then
    core.graphics.text_2d(self.opts.title, constants.vec2.new(gx + 10, y), constants.FONT_SIZE, constants.color.white(240), false)
  end
  y = y + 20

  -- flatten rows
  local rows = {}
  local function clone(t)
    local r = {}; for i=1,#(t or {}) do r[i]=t[i] end; return r
  end
  local function add_node(node, level, lanes, idx, cnt)
    table.insert(rows, { node=node, level=level, lanes=lanes or {}, index=idx or 1, count=cnt or 1 })
    if self._expanded[node] ~= false and self:_is_container(node) then
      local ch = self:_get_children(node)
      for i=1,#ch do
        local nxt = clone(lanes or {})
        nxt[level+1] = (i < #ch)
        add_node(ch[i], level+1, nxt, i, #ch)
      end
    end
  end
  local roots = self:_get_roots()
  for i=1,#roots do add_node(roots[i], 0, {}, i, #roots) end

  -- helpers for dotted lines
  local function dot_v(x, y1, y2, col)
    local y0 = y1
    while y0 <= y2 do core.graphics.rect_2d_filled(constants.vec2.new(x, y0), 1, 1, col, 1); y0 = y0 + 2 end
  end
  local function dot_h(x1, x2, y0, col)
    local x = x1; while x < x2 do core.graphics.rect_2d_filled(constants.vec2.new(x, y0), 1, 1, col, 1); x = x + 2 end
  end

  -- draw rows
  local col_lane = constants.color.white(180)
  local col_edge = constants.color.white(200)
  local mouse = constants.mouse_state.position
  for i=1,#rows do
    local r = rows[i]
    local row_y = y + (i-1)*self.row_h
    if row_y + self.row_h > gy + h - 6 then break end
    local indent = r.level * self.indent
    local has_children = self:_is_container(r.node)
    local toggle_w = 10
    local anchor_x = gx + 8 + r.level * self.indent
    local toggle_x = anchor_x - math.floor(toggle_w/2)

    -- lanes from ancestors
    for lvl=1,r.level-1 do
      if r.lanes and r.lanes[lvl] then
        local vx = gx + 8 + lvl * self.indent
        dot_v(vx, row_y, row_y + self.row_h - 1, col_lane)
      end
    end
    if r.level>0 then
      local cx = gx + 8 + (r.level-1)*self.indent
      local cy = row_y + math.floor(self.row_h/2)
      dot_v(cx, row_y + 2, cy, col_edge)
      if r.lanes and r.lanes[r.level] then dot_v(cx, cy+1, row_y + self.row_h - 1, col_edge) end
      local label_pad = has_children and (toggle_w + 6) or 4
      local label_x = gx + 10 + indent + label_pad
      dot_h(cx, label_x - 2, cy, col_edge)
    end

    -- toggle box and text
    if has_children then
      local bx = toggle_x
      local by = row_y + math.floor((self.row_h - toggle_w) / 2)
      core.graphics.rect_2d(constants.vec2.new(bx, by), toggle_w, toggle_w, constants.color.white(140), 1, 2)
      core.graphics.rect_2d_filled(constants.vec2.new(bx + 2, by + math.floor(toggle_w/2)), toggle_w - 4, 1, constants.color.white(230), 1)
      if self._expanded[r.node] == false then
        core.graphics.rect_2d_filled(constants.vec2.new(bx + math.floor(toggle_w/2), by + 2), 1, toggle_w - 4, constants.color.white(230), 1)
      end
      local over_toggle = (mouse.x >= bx and mouse.x <= bx + toggle_w and mouse.y >= by and mouse.y <= by + toggle_w)
      if over_toggle and constants.mouse_state.left_clicked then
        local cur = self._expanded[r.node]
        local expanded = (cur ~= false)
        self._expanded[r.node] = (not expanded)
      end
    end
    local label = self:_get_label(r.node)
    local text_y = row_y + math.floor((self.row_h - (constants.FONT_SIZE or 14)) / 2) - 1
    core.graphics.text_2d(label, constants.vec2.new(gx + 10 + indent + (has_children and (toggle_w+6) or 4), text_y), constants.FONT_SIZE, constants.color.white(235), false)
    -- selection
    local over_row = (mouse.x >= gx + 4 and mouse.x <= gx + self.w - 8 and mouse.y >= row_y and mouse.y <= row_y + self.row_h)
    if over_row and constants.mouse_state.left_clicked and self.on_select then self.on_select(self, r.node) end
  end
end

return Treeview


