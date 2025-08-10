-- Rejuvenation (ID: 774)
-- Resto HoT maintenance
return function(engine)
  engine:register_spell({
    id = 774,
    name = "Rejuvenation",
    priority = 90,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(774) then return false end
      if ctx.is_spec and not ctx.is_spec('Restoration') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'restoration') and not ctx.is_spec then return false end
      local ally = (ctx.get_ally_lowest and ctx.get_ally_lowest()) or (ctx.get_player and ctx.get_player())
      return ally ~= nil
    end,

    should_use = function(ctx)
      local ally = (ctx.get_ally_lowest and ctx.get_ally_lowest()) or (ctx.get_player and ctx.get_player())
      if not ally then return false end
      if ctx.has_buff and ctx.has_buff(ally, 774) then return false end
      return (ally.health_pct or 100) < 92
    end,

    execute = function(ctx)
      local ally = (ctx.get_ally_lowest and ctx.get_ally_lowest()) or (ctx.get_player and ctx.get_player())
      if ally and ctx.cast_spell_on then return ctx.cast_spell_on(774, ally) end
      return false
    end,
  })
end


