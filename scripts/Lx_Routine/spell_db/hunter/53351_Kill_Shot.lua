-- Kill Shot (ID: 53351)
-- Execute for Hunter
return function(engine)
  engine:register_spell({
    id = 53351,
    name = "Kill Shot",
    priority = 105,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(53351) then return false end
      return true
    end,

    should_use = function(ctx)
      local hp = ctx.target and (ctx.target.health_pct or 100) or 100
      return hp <= 20
    end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(53351, ctx.target) end
      return false
    end,
  })
end


