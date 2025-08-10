-- Regrowth (ID: 8936)
-- Resto fast heal with HoT
return function(engine)
  engine:register_spell({
    id = 8936,
    name = "Regrowth",
    priority = 92,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(8936) then return false end
      if ctx.is_spec and not ctx.is_spec('Restoration') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'restoration') and not ctx.is_spec then return false end
      local ally = (ctx.get_ally_urgent and ctx.get_ally_urgent()) or (ctx.get_ally_lowest and ctx.get_ally_lowest())
      return ally ~= nil
    end,

    should_use = function(ctx)
      local ally = (ctx.get_ally_urgent and ctx.get_ally_urgent()) or (ctx.get_ally_lowest and ctx.get_ally_lowest())
      if not ally then return false end
      return (ally.health_pct or 100) <= 70
    end,

    execute = function(ctx)
      local ally = (ctx.get_ally_urgent and ctx.get_ally_urgent()) or (ctx.get_ally_lowest and ctx.get_ally_lowest())
      if ally and ctx.cast_spell_on then return ctx.cast_spell_on(8936, ally) end
      return false
    end,
  })
end


