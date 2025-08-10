-- Hammer of Wrath (ID: 24275)
-- Execute for Paladin
return function(engine)
  engine:register_spell({
    id = 24275,
    name = "Hammer of Wrath",
    priority = 105,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(24275) then return false end
      return true
    end,

    should_use = function(ctx)
      local hp = ctx.target and (ctx.target.health_pct or 100) or 100
      return hp <= 20
    end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(24275, ctx.target) end
      return false
    end,
  })
end


