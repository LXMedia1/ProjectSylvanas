-- Shadowstep (ID: 36554)
-- Mobility gap closer
return function(engine)
  engine:register_spell({
    id = 36554,
    name = "Shadowstep",
    priority = 80,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(36554) then return false end
      local d = ctx.distance_to and ctx.distance_to(ctx.target)
      return d and d > 10 and d < 25
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(36554, ctx.target) end
      return false
    end,
  })
end


