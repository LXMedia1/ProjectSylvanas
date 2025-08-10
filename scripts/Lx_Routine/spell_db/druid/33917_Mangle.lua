-- Mangle (ID: 33917)
-- Guardian generator
return function(engine)
  engine:register_spell({
    id = 33917,
    name = "Mangle",
    priority = 95,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(33917) then return false end
      if ctx.is_spec and not ctx.is_spec('Guardian') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'guardian') and not ctx.is_spec then return false end
      local d = ctx.distance_to and ctx.distance_to(ctx.target)
      return d and d <= 5
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(33917, ctx.target) end
      return false
    end,
  })
end


