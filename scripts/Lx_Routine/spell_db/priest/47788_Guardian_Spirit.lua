-- Guardian Spirit (ID: 47788)
-- Holy external; save a critical ally
return function(engine)
  engine:register_spell({
    id = 47788,
    name = "Guardian Spirit",
    priority = 107,

    is_usable = function(ctx)
      if not ctx then return false end
      local ally = (ctx.get_tank_urgent and ctx.get_tank_urgent()) or (ctx.get_ally_critical and ctx.get_ally_critical())
      if not ally then return false end
      if ctx.can_cast and not ctx.can_cast(47788) then return false end
      return true
    end,

    should_use = function(ctx)
      local ally = (ctx.get_tank_urgent and ctx.get_tank_urgent()) or (ctx.get_ally_critical and ctx.get_ally_critical())
      if not ally then return false end
      return (ally.health_pct or 100) <= 25
    end,

    execute = function(ctx)
      local ally = (ctx.get_tank_urgent and ctx.get_tank_urgent()) or (ctx.get_ally_critical and ctx.get_ally_critical())
      if ally and ctx.cast_spell_on then
        return ctx.cast_spell_on(47788, ally)
      end
      return false
    end,
  })
end


