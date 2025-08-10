-- Flash of Light (ID: 19750)
-- Fast, expensive single-target heal
return function(engine)
  engine:register_spell({
    id = 19750,
    name = "Flash of Light",
    priority = 116,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(19750) then return false end
      return true
    end,

    should_use = function(ctx)
      local ally = (ctx.get_ally_urgent and ctx.get_ally_urgent()) or (ctx.get_ally_lowest and ctx.get_ally_lowest())
      if not ally then return false end
      return (ally.health_pct or 100) <= 55
    end,

    execute = function(ctx)
      local ally = (ctx.get_ally_urgent and ctx.get_ally_urgent()) or (ctx.get_ally_lowest and ctx.get_ally_lowest())
      if ally and ctx.cast_spell_on then return ctx.cast_spell_on(19750, ally) end
      return false
    end,
  })
end


