-- Blessing of Protection (ID: 1022)
-- Physical immunity; use to save ally from lethal physical damage
return function(engine)
  engine:register_spell({
    id = 1022,
    name = "Blessing of Protection",
    priority = 150,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(1022) then return false end
      local ally = (ctx.get_ally_critical and ctx.get_ally_critical()) or (ctx.get_player and ctx.get_player())
      return ally ~= nil
    end,

    should_use = function(ctx)
      local ally = (ctx.get_ally_critical and ctx.get_ally_critical()) or (ctx.get_player and ctx.get_player())
      if not ally then return false end
      local incoming = ctx.expected_damage_in and ctx.expected_damage_in(ally, 2.0) or 0
      return incoming and incoming > (ally.health_max or 0) * 0.5
    end,

    execute = function(ctx)
      local ally = (ctx.get_ally_critical and ctx.get_ally_critical()) or (ctx.get_player and ctx.get_player())
      if ally and ctx.cast_spell_on then return ctx.cast_spell_on(1022, ally) end
      return false
    end,
  })
end


