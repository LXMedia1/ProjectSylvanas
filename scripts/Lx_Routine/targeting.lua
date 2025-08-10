local Targeting = {}

local function is_valid_enemy(unit)
  return unit and unit.is_enemy and (not unit.is_dead)
end

local function score_enemy(ctx, unit)
  local score = 0
  if not is_valid_enemy(unit) then return -1 end
  -- Prefer current target slightly
  if ctx.target and unit == ctx.target then score = score + 2 end
  -- Prefer lower time-to-die if available
  if ctx.time_to_die then
    local ttd = ctx.time_to_die(unit)
    if ttd and ttd > 0 then score = score + (1000 / (10 + ttd)) end
  end
  -- Prefer closer targets
  if ctx.distance_to then
    local d = ctx.distance_to(unit)
    if d then score = score + (1000 / (5 + d)) end
  end
  -- Prefer attacking our aggroed target
  if ctx.is_targeting_me and ctx.is_targeting_me(unit) then score = score + 50 end
  -- Boss/elite bonus
  if ctx.is_boss_or_elite and ctx.is_boss_or_elite(unit) then score = score + 25 end
  return score
end

function Targeting.select_best_target(ctx)
  local list = (ctx.enemies and ctx.enemies()) or {}
  local best, best_score = nil, -1
  for i = 1, #list do
    local u = list[i]
    local s = score_enemy(ctx, u)
    if s > best_score then
      best, best_score = u, s
    end
  end
  return best
end

return Targeting


