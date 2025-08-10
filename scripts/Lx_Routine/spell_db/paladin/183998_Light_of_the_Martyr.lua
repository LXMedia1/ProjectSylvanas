-- Light of the Martyr (ID: 183998)
-- Instant heal at cost of self health
return function(engine)
  engine:register_spell({
    id = 183998,
    name = "Light of the Martyr",
    priority = 118,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(183998) then return false end
      local ally = (ctx.get_ally_urgent and ctx.get_ally_urgent()) or (ctx.get_ally_lowest and ctx.get_ally_lowest())
      return ally ~= nil
    end,

    should_use = function(ctx)
      local ally = (ctx.get_ally_urgent and ctx.get_ally_urgent()) or (ctx.get_ally_lowest and ctx.get_ally_lowest())
      if not ally then return false end
      return (ally.health_pct or 100) <= 40
    end,

    execute = function(ctx)
      local ally = (ctx.get_ally_urgent and ctx.get_ally_urgent()) or (ctx.get_ally_lowest and ctx.get_ally_lowest())
      if ally and ctx.cast_spell_on then return ctx.cast_spell_on(183998, ally) end
      return false
    end,
  })
end


