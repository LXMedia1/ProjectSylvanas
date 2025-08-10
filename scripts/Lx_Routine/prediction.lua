local Prediction = {}

local tracked = {}
local last_sample_ms = 0
local SAMPLE_INTERVAL_MS = 200
local EMA_ALPHA = 0.3

local function unit_key(u)
  if not u then return nil end
  if u.get_guid then return tostring(u:get_guid()) end
  if u.get_id then return 'id:' .. tostring(u:get_id()) end
  return tostring(u)
end

local function get_health(u)
  if not u then return nil, nil end
  local hp = u.health_current or (u.get_health and u:get_health()) or nil
  local hpmax = u.health_max or (u.get_health_max and u:get_health_max()) or nil
  return hp, hpmax
end

local function track_unit(u)
  local key = unit_key(u)
  if not key then return end
  local stat = tracked[key]
  if not stat then
    local hp, hpmax = get_health(u)
    tracked[key] = {
      ref = u,
      hp = hp or 0,
      hpmax = hpmax or 1,
      dps = 0,
      last_ms = core.time() or 0,
    }
    return
  end
  -- Update hpmax in case of changes
  local _, hpmax = get_health(u)
  if hpmax then stat.hpmax = hpmax end
end

local function sample_unit(u, now)
  local key = unit_key(u)
  if not key then return end
  local stat = tracked[key]
  if not stat then return end
  local hp, hpmax = get_health(u)
  if not hp or not hpmax then return end
  local dt_ms = now - (stat.last_ms or now)
  if dt_ms <= 0 then return end

  local delta = (stat.hp or hp) - hp
  if delta < 0 then delta = 0 end -- healing taken; ignore for damage dps
  local inst_dps = (delta) * 1000.0 / dt_ms
  if inst_dps < 0 then inst_dps = 0 end
  stat.dps = (EMA_ALPHA * inst_dps) + ((1 - EMA_ALPHA) * (stat.dps or 0))
  stat.hp = hp
  stat.hpmax = hpmax
  stat.last_ms = now
end

local function enumerate_units()
  local c = rawget(_G, 'core')
  local units = {}
  if c and c.object_manager then
    local me = c.object_manager.get_local_player and c.object_manager.get_local_player() or nil
    if me then units[#units+1] = me end
  end
  if c and c.group and c.group.members then
    local members = c.group.members()
    for i = 1, #members do units[#units+1] = members[i] end
  elseif c and c.object_manager and c.object_manager.get_party then
    local members = c.object_manager.get_party()
    for i = 1, #members do units[#units+1] = members[i] end
  end
  return units
end

function Prediction.start()
  core.register_on_update_callback(function()
    local now = core.time() or 0
    if (now - last_sample_ms) < SAMPLE_INTERVAL_MS then return end
    last_sample_ms = now
    local units = enumerate_units()
    for i = 1, #units do
      local u = units[i]
      track_unit(u)
      sample_unit(u, now)
    end
  end)
end

function Prediction.incoming_dps(unit)
  local key = unit_key(unit)
  if not key then return 0 end
  local s = tracked[key]
  return (s and s.dps) or 0
end

function Prediction.expected_damage_in(unit, horizon_seconds)
  local dps = Prediction.incoming_dps(unit)
  return dps * (horizon_seconds or 1.5)
end

function Prediction.time_to_die(unit)
  local key = unit_key(unit)
  if not key then return nil end
  local s = tracked[key]
  if not s then return nil end
  local dps = s.dps or 0
  if dps <= 0 then return nil end
  local hp = s.hp or 0
  return hp / dps
end

return Prediction


