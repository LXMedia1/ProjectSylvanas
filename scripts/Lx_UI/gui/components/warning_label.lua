local constants = require("gui/utils/constants")

local WarningLabel = {}
WarningLabel.__index = WarningLabel

function WarningLabel:new(owner_gui, text, x, y, duration_ms)
  local o = setmetatable({}, WarningLabel)
  o.gui = owner_gui
  o.text = tostring(text or "")
  o.x = tonumber(x or 0) or 0
  o.y = tonumber(y or 0) or 0
  o.start_raw = (core.time and core.time()) or 0
  o.duration_ms = tonumber(duration_ms or 0) or 0 -- optional; auto-total ensures 3 pulses with integrated fade
  o.pulse_period_ms = 800 -- slower pulse for better readability
  o.pulse_count = 2
  o.visible_if = nil
  o.size = (constants.FONT_SIZE or 14) + 8
  -- auto unit calibration (assume ms; switch to seconds→ms if deltas look like seconds)
  o._scale = 1 -- multiply raw time by this to get ms
  o._calibrated = false
  o._last_raw = nil
  o._zero_frames = 0
  return o
end

function WarningLabel:set_visible_if(fn) self.visible_if = fn end

function WarningLabel:_now_ms()
  local raw = (core.time and core.time()) or 0
  if not self._calibrated then
    if self._last_raw ~= nil then
      local d = raw - self._last_raw
      if d == 0 then
        self._zero_frames = self._zero_frames + 1
        if self._zero_frames >= 3 then
          self._scale = 1000; self._calibrated = true
        end
      else
        -- Heuristic: typical frame deltas (ms-units) are > 4 and < 100; seconds-units are ~1
        if d >= 4 and d < 200 then self._scale = 1; self._calibrated = true
        elseif d >= 1 and d <= 2 then self._scale = 1000; self._calibrated = true end
      end
    end
    self._last_raw = raw
  end
  return raw * (self._scale or 1)
end

local function max(a, b) if a > b then return a else return b end end

function WarningLabel:_get_total_ms()
  local pulses_ms = (self.pulse_count or 3) * (self.pulse_period_ms or 800)
  local auto_total = pulses_ms
  if (self.duration_ms or 0) <= 0 then return auto_total end
  return max(self.duration_ms, auto_total)
end

function WarningLabel:is_visible()
  local now_ms = self:_now_ms()
  local start_ms = (self.start_raw or 0) * (self._scale or 1)
  if now_ms >= (start_ms + self:_get_total_ms()) then return false end
  if self.visible_if then return not not self.visible_if(self) end
  return true
end

function WarningLabel:is_expired()
  local now_ms = self:_now_ms()
  local start_ms = (self.start_raw or 0) * (self._scale or 1)
  return now_ms >= (start_ms + self:_get_total_ms())
end

function WarningLabel:set_size(sz)
  local n = tonumber(sz)
  if n and n > 0 then self.size = n end
end

function WarningLabel:render()
  if not (self.gui and self.gui.is_open) then return end
  if not self:is_visible() then return end
  if not (core.graphics and core.graphics.text_2d) then return end
  local now_ms = self:_now_ms()
  local start_ms = (self.start_raw or 0) * (self._scale or 1)
  local elapsed = now_ms - start_ms
  local period = self.pulse_period_ms or 800
  local count = self.pulse_count or 3
  local pulses_ms = count * period
  local r, g, b, alpha
  if elapsed <= pulses_ms then
    local cycle = math.floor(elapsed / period) -- 0..count-1
    local t = elapsed - (cycle * period)
    local u = t / period -- 0..1
    local sin_half = math.sin(3.1415926535898 * u) -- smooth up/down in each pulse
    local a_norm
    local last_cycle = count - 1
    if cycle == 0 then
      -- not visible -> max -> medium
      a_norm = (0.75 * sin_half) + (0.5 * u)
    elseif cycle < last_cycle then
      -- medium -> max -> medium (for intermediate cycles if any)
      a_norm = 0.5 + 0.5 * sin_half
    else
      -- last pulse: medium -> max -> not visible
      a_norm = (0.75 * sin_half) + (0.5 * (1 - u))
    end
    if a_norm < 0 then a_norm = 0 elseif a_norm > 1 then a_norm = 1 end
    r = 205 + math.floor(50 * a_norm)
    g = 58 + math.floor(18 * (1 - a_norm))
    b = 58 + math.floor(18 * (1 - a_norm))
    alpha = math.floor(255 * a_norm)
  else
    return
  end
  local col = constants.color.new(r, g, b, alpha)
  local px = self.gui.x + self.x
  local py = self.gui.y + self.y
  local fs = self.size or (constants.FONT_SIZE or 14)
  -- subtle shadow for readability
  core.graphics.text_2d(self.text, constants.vec2.new(px + 1, py + 1), fs, constants.color.new(0, 0, 0, math.min(alpha, 200)), false)
  core.graphics.text_2d(self.text, constants.vec2.new(px, py), fs, col, false)
end

return WarningLabel


