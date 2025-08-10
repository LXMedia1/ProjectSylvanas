-- Ferocious Bite (ID: 22568)
-- Feral finisher
return function(engine)
  engine:register_spell({
    id = 22568,
    name = "Ferocious Bite",
    priority = 96,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(22568) then return false end
      if ctx.is_spec and not ctx.is_spec('Feral') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'feral') and not ctx.is_spec then return false end
      local d = ctx.distance_to and ctx.distance_to(ctx.target)
      return d and d <= 5
    end,

    should_use = function(ctx)
      if ctx.combo_points and ctx.combo_points() then
        return ctx.combo_points() >= 5
      end
      return false
    end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(22568, ctx.target) end
      return false
    end,
  })
end


