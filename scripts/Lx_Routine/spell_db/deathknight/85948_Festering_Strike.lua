-- Festering Strike (ID: 85948)
-- Unholy builder
return function(engine)
  engine:register_spell({
    id = 85948,
    name = "Festering Strike",
    priority = 90,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(85948) then return false end
      if ctx.is_spec and not ctx.is_spec('Unholy') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'unholy') and not ctx.is_spec then return false end
      local d = ctx.distance_to and ctx.distance_to(ctx.target)
      return d and d <= 5
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(85948, ctx.target) end
      return false
    end,
  })
end


