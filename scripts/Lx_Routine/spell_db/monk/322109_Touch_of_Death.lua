-- Touch of Death (ID: 322109)
-- Execute-style finisher when target is low or conditions met
return function(engine)
  engine:register_spell({
    id = 322109,
    name = "Touch of Death",
    priority = 110,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(322109) then return false end
      return true
    end,

    should_use = function(ctx)
      local hp = ctx.target and (ctx.target.health_pct or 100) or 100
      return hp <= 15
    end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(322109, ctx.target) end
      return false
    end,
  })
end


