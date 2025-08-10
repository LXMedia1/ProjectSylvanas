local Utils = {}

function Utils.is_cast_interruptible(ctx, unit)
  if not unit then return false end
  local c = rawget(_G, 'core')
  if c and c.cast and c.cast.is_interruptible then
    return c.cast.is_interruptible(unit)
  end
  if unit.is_casting and unit:is_casting() then
    if unit.get_cast_info then
      local info = unit:get_cast_info()
      if info and info.uninterruptible then return false end
    end
    return true
  end
  return false
end

function Utils.can_dispel_enemy(ctx, unit)
  local c = rawget(_G, 'core')
  if c and c.dispel and c.dispel.can_dispel_enemy then
    return c.dispel.can_dispel_enemy(unit)
  end
  if c and c.auras and c.auras.has_magic_buff then
    return c.auras.has_magic_buff(unit) == true
  end
  return false
end

function Utils.can_dispel_ally(ctx, unit)
  local c = rawget(_G, 'core')
  if c and c.dispel and c.dispel.can_dispel_ally then
    return c.dispel.can_dispel_ally(unit)
  end
  if c and c.auras and c.auras.has_dispellable_debuff then
    return c.auras.has_dispellable_debuff(unit) == true
  end
  return false
end

return Utils


