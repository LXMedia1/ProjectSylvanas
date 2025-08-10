local Healing = {}

local function iter_group(ctx)
  if ctx.group_members then
    local members = ctx.group_members()
    local i = 0
    return function()
      i = i + 1
      return members[i]
    end
  end
  return function() return nil end
end

function Healing.find_ally_critical(ctx)
  local best, best_hp = nil, 101
  for m in iter_group(ctx) do
    if m and not m.is_dead then
      local hp = m.health_pct or 100
      if hp < best_hp then
        best, best_hp = m, hp
      end
    end
  end
  if not best and ctx.get_player then
    local me = ctx.get_player()
    if me then best = me end
  end
  return best_hp <= 35 and best or nil
end

function Healing.find_ally_lowest(ctx)
  local best, best_hp = nil, 101
  for m in iter_group(ctx) do
    if m and not m.is_dead then
      local hp = m.health_pct or 100
      if hp < best_hp then
        best, best_hp = m, hp
      end
    end
  end
  if not best and ctx.get_player then
    local me = ctx.get_player()
    if me then best, best_hp = me, me.health_pct or 100 end
  end
  return best
end

function Healing.find_ally_dispellable(ctx)
  for m in iter_group(ctx) do
    if m and not m.is_dead then
      if ctx.can_dispel_ally and ctx.can_dispel_ally(m) then
        return m
      end
    end
  end
  return nil
end

function Healing.find_ally_to_res(ctx)
  for m in iter_group(ctx) do
    if m and m.is_dead then
      if ctx.can_resurrect and ctx.can_resurrect(m) then
        return m
      end
    end
  end
  return nil
end

return Healing


