-- Kick (ID: 1766)
-- Interrupt
return function(engine)
  engine:register_spell({
    id = 1766,
    name = "Kick",
    priority = 120,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(1766) then return false end
      if ctx.is_cast_interruptible then return ctx.is_cast_interruptible(ctx.target) end
      return false
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(1766, ctx.target) end
      return false
    end,
  })
end


