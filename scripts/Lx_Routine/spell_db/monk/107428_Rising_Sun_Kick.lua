-- Rising Sun Kick (ID: 107428)
-- Windwalker spender
return function(engine)
  engine:register_spell({
    id = 107428,
    name = "Rising Sun Kick",
    priority = 90,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(107428) then return false end
      if ctx.is_spec and not ctx.is_spec('Windwalker') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'windwalker') and not ctx.is_spec then return false end
      local d = ctx.distance_to and ctx.distance_to(ctx.target)
      return d and d <= 5
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(107428, ctx.target) end
      return false
    end,
  })
end


