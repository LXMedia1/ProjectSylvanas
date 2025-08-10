-- Tiger Palm (ID: 100780)
-- Monk builder
return function(engine)
  engine:register_spell({
    id = 100780,
    name = "Tiger Palm",
    priority = 40,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(100780) then return false end
      local d = ctx.distance_to and ctx.distance_to(ctx.target)
      return d and d <= 5
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(100780, ctx.target) end
      return false
    end,
  })
end


