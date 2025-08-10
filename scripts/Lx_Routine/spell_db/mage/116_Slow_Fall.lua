-- Slow Fall (ID: 130)
-- Safety utility; preempt falling damage if context detects falling
return function(engine)
  engine:register_spell({
    id = 130,
    name = "Slow Fall",
    priority = 200,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(130) then return false end
      if ctx.is_falling and ctx.is_falling() then return true end
      return false
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      local me = ctx.get_player and ctx.get_player()
      if me and ctx.cast_spell_on then return ctx.cast_spell_on(130, me) end
      return false
    end,
  })
end


