-- Blessing of Sacrifice (ID: 6940)
-- External defensive; redirect damage from a critical ally
return function(engine)
  engine:register_spell({
    id = 6940,
    name = "Blessing of Sacrifice",
    priority = 160,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(6940) then return false end
      local ally = (ctx.get_tank_urgent and ctx.get_tank_urgent()) or (ctx.get_ally_critical and ctx.get_ally_critical())
      return ally ~= nil
    end,

    should_use = function(ctx)
      local ally = (ctx.get_tank_urgent and ctx.get_tank_urgent()) or (ctx.get_ally_critical and ctx.get_ally_critical())
      if not ally then return false end
      local incoming = ctx.expected_damage_in and ctx.expected_damage_in(ally, 2.0) or 0
      return incoming and incoming > (ally.health_max or 0) * 0.4
    end,

    execute = function(ctx)
      local ally = (ctx.get_tank_urgent and ctx.get_tank_urgent()) or (ctx.get_ally_critical and ctx.get_ally_critical())
      if ally and ctx.cast_spell_on then return ctx.cast_spell_on(6940, ally) end
      return false
    end,
  })
end


