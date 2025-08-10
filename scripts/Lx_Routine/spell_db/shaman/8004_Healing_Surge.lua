-- Healing Surge (ID: 8004)
-- Fast emergency heal
return function(engine)
  engine:register_spell({
    id = 8004,
    name = "Healing Surge",
    priority = 112,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(8004) then return false end
      local ally = (ctx.get_ally_urgent and ctx.get_ally_urgent()) or (ctx.get_ally_lowest and ctx.get_ally_lowest())
      return ally ~= nil
    end,

    should_use = function(ctx)
      local ally = (ctx.get_ally_urgent and ctx.get_ally_urgent()) or (ctx.get_ally_lowest and ctx.get_ally_lowest())
      return ally and ((ally.health_pct or 100) <= 50)
    end,

    execute = function(ctx)
      local ally = (ctx.get_ally_urgent and ctx.get_ally_urgent()) or (ctx.get_ally_lowest and ctx.get_ally_lowest())
      if ally and ctx.cast_spell_on then return ctx.cast_spell_on(8004, ally) end
      return false
    end,
  })
end


