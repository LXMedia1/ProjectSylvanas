-- Blade of Justice (ID: 184575)
-- Ret generator
return function(engine)
  engine:register_spell({
    id = 184575,
    name = "Blade of Justice",
    priority = 82,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(184575) then return false end
      local d = ctx.distance_to and ctx.distance_to(ctx.target)
      return d and d <= 12
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(184575, ctx.target) end
      return false
    end,
  })
end


