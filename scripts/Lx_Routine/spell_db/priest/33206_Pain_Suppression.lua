-- Pain Suppression (ID: 33206)
-- Disc external; use on tank/ally in critical danger
return function(engine)
  engine:register_spell({
    id = 33206,
    name = "Pain Suppression",
    priority = 105,

    is_usable = function(ctx)
      if not ctx then return false end
      local ally = (ctx.get_tank_urgent and ctx.get_tank_urgent()) or (ctx.get_ally_critical and ctx.get_ally_critical())
      if not ally then return false end
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Pain Suppression") or 33206)) or 33206
      if ctx.can_cast and not ctx.can_cast(sid) then return false end
      return true
    end,

    should_use = function(ctx)
      local ally = (ctx.get_tank_urgent and ctx.get_tank_urgent()) or (ctx.get_ally_critical and ctx.get_ally_critical())
      if not ally then return false end
      return (ally.health_pct or 100) <= 35
    end,

    execute = function(ctx)
      local ally = (ctx.get_tank_urgent and ctx.get_tank_urgent()) or (ctx.get_ally_critical and ctx.get_ally_critical())
      if ally and ctx.cast_spell_on then
        local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Pain Suppression") or 33206)) or 33206
        return ctx.cast_spell_on(sid, ally)
      end
      return false
    end,
  })
end


