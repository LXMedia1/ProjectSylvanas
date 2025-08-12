local constants = require("gui/utils/constants")
local helpers = require("gui/utils/helpers")

local ScrollArea = {}
ScrollArea.__index = ScrollArea

-- A simple clipped viewport with vertical scroll and optional scrollbar.
function ScrollArea:new(owner_gui, x, y, w, h)
  local o = setmetatable({}, ScrollArea)
  o.gui = owner_gui
  o.x, o.y, o.w, o.h = x or 0, y or 0, w or 200, h or 150
  o.content_h = h or 150
  o.scroll_y = 0
  o.snap_step = nil -- optional pixel step to snap scroll positions
  o.snap_offset = 0 -- anchor offset for snapping
  o.visible_if = nil
  o._dragging_bar = false
  return o
end

function ScrollArea:set_visible_if(fn) self.visible_if = fn end
function ScrollArea:is_visible() if self.visible_if then return not not self.visible_if(self) end return true end

function ScrollArea:set_content_height(h)
  self.content_h = math.max(h or 0, self.h)
  if self.scroll_y > self.content_h - self.h then self.scroll_y = math.max(0, self.content_h - self.h) end
end

-- get_view_rect is provided later after caching viewport in render_begin

function ScrollArea:scroll(delta)
  -- Snap-aware max scroll so the last snapped position fits cleanly
  local raw_overflow = math.max(0, (self.content_h or self.h) - self.h)
  local max_scroll = raw_overflow
  if self.snap_step and self.snap_step > 0 then
    local step = self.snap_step
    local off = self.snap_offset or 0
    max_scroll = math.max(0, math.floor(((raw_overflow - off) / step)) * step + off)
  end
  local next_y
  if self.snap_step and self.snap_step > 0 then
    local step = self.snap_step
    local off = self.snap_offset or 0
    if delta > 0 then
      local steps = math.max(1, math.floor((delta / step) + 0.0001))
      local cur_idx = math.floor(((self.scroll_y - off) / step) + 0.0001)
      next_y = (cur_idx + steps) * step + off
    elseif delta < 0 then
      local steps = math.max(1, math.floor(((-delta) / step) + 0.0001))
      local cur_idx = math.ceil(((self.scroll_y - off) / step) - 0.0001)
      next_y = (cur_idx - steps) * step + off
    else
      next_y = self.scroll_y
    end
    if next_y > max_scroll then next_y = max_scroll end
    if next_y < 0 then next_y = 0 end
  else
    next_y = math.max(0, math.min(self.scroll_y + delta, max_scroll))
  end
  self.scroll_y = next_y
end

function ScrollArea:render_begin()
  if not (self.gui and self.gui.is_open and self:is_visible()) then return false end
  if not core.graphics then return false end
  local gx, gy, w, h = self.gui.x + self.x, self.gui.y + self.y, self.w, self.h
  -- background and border
  core.graphics.rect_2d_filled(constants.vec2.new(gx, gy), w, h, constants.color.new(14, 18, 30, 220), 6)
  core.graphics.rect_2d(constants.vec2.new(gx, gy), w, h, constants.color.new(32, 40, 70, 255), 1, 6)
  -- cache viewport for manual clipping consumers
  self._vp_x, self._vp_y, self._vp_w, self._vp_h = gx, gy, w, h
  -- wheel scroll when hovered
  if core.input and core.input.get_mouse_wheel then
    local m = constants.mouse_state.position
    if helpers.is_point_in_rect(m.x, m.y, gx, gy, w, h) then
      local wheel = core.input.get_mouse_wheel()
      if wheel ~= 0 then
        local step = (self.snap_step and self.snap_step > 0) and self.snap_step or 12
        self:scroll(-wheel * step)
      end
    end
  end
  -- set scissor/clip if available
  if core.graphics.set_scissor then
    core.graphics.set_scissor(true, gx, gy, w, h)
  end
  return true
end

function ScrollArea:render_end()
  if core.graphics and core.graphics.set_scissor then
    core.graphics.set_scissor(false, 0, 0, 0, 0)
  end
  -- scrollbar (vertical) when content exceeds viewport
  local overflow = (self.content_h or self.h) - self.h
  if overflow > 1 then
    local gx, gy = self.gui.x + self.x, self.gui.y + self.y
    local bar_w = 6
    local track_x = gx + self.w - bar_w - 4
    local track_y = gy + 4
    local track_h = self.h - 8
    core.graphics.rect_2d_filled(constants.vec2.new(track_x, track_y), bar_w, track_h, constants.color.new(26, 32, 48, 200), 3)
    -- knob size proportional to ratio
    local ratio = self.h / (self.content_h or self.h)
    local knob_h = math.max(16, math.floor(track_h * ratio))
    local t = (overflow > 0) and (self.scroll_y / overflow) or 0
    local knob_y = track_y + math.floor((track_h - knob_h) * t)
    local m = constants.mouse_state.position
    local over_knob = helpers.is_point_in_rect(m.x, m.y, track_x, knob_y, bar_w, knob_h)
    local col = over_knob and constants.color.new(86, 120, 200, 230) or constants.color.new(60, 90, 160, 220)
    core.graphics.rect_2d_filled(constants.vec2.new(track_x, knob_y), bar_w, knob_h, col, 3)
    -- drag knob
    if over_knob and constants.mouse_state.left_down and not self._dragging_bar then
      self._dragging_bar = true
      self._drag_off = m.y - knob_y
    end
    if self._dragging_bar then
      if constants.mouse_state.left_down then
        local new_knob_y = m.y - (self._drag_off or 0)
        if new_knob_y < track_y then new_knob_y = track_y end
        if new_knob_y + knob_h > track_y + track_h then new_knob_y = track_y + track_h - knob_h end
        local nt = (new_knob_y - track_y) / (track_h - knob_h)
        local target = math.max(0, math.min(overflow, math.floor(overflow * nt + 0.5)))
        if self.snap_step and self.snap_step > 0 then
          local step = self.snap_step
          local off = self.snap_offset or 0
          local max_snap = math.max(0, math.floor(((overflow - off) / step)) * step + off)
          local snapped = math.floor(((target - off) / step) + 0.5) * step + off
          if snapped > max_snap then snapped = max_snap end
          if snapped < 0 then snapped = 0 end
          target = snapped
        end
        self.scroll_y = target
      else
        self._dragging_bar = false
      end
    end
  end
end

function ScrollArea:set_render_content(cb)
  self.render_content = cb
end

function ScrollArea:get_view_rect()
  return self._vp_x or (self.gui.x + self.x), self._vp_y or (self.gui.y + self.y), self._vp_w or self.w, self._vp_h or self.h, self.scroll_y or 0
end

function ScrollArea:set_snap(step, offset)
  if step and step > 0 then
    self.snap_step = math.floor(step)
    self.snap_offset = math.floor(offset or 0)
  else
    self.snap_step = nil
    self.snap_offset = 0
  end
end

return ScrollArea


