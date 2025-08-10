-- Templar's Verdict (ID: 85256)
-- Ret spender
return function(engine)
  engine:register_spell({
    id = 85256,
    name = "Templar's Verdict",
    priority = 90,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(85256) then return false end
      local d = ctx.distance_to and ctx.distance_to(ctx.target)
      return d and d <= 5
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(85256, ctx.target) end
      return false
    end,
  })
end


