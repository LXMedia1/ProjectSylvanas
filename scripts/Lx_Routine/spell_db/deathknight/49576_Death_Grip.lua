-- Death Grip (ID: 49576)
-- Utility: grip target to you
return function(engine)
  engine:register_spell({
    id = 49576,
    name = "Death Grip",
    priority = 70,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(49576) then return false end
      if ctx.should_grip and not ctx.should_grip(ctx.target) then return false end
      local d = ctx.distance_to and ctx.distance_to(ctx.target)
      return d and d > 10 and d < 30
    end,

    should_use = function(ctx)
      return true
    end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(49576, ctx.target) end
      return false
    end,
  })
end


