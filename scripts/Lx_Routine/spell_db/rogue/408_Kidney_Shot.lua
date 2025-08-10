-- Kidney Shot (ID: 408)
-- Stun finisher
return function(engine)
  engine:register_spell({
    id = 408,
    name = "Kidney Shot",
    priority = 115,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(408) then return false end
      return true
    end,

    should_use = function(ctx)
      if ctx.combo_points and ctx.combo_points() then
        return ctx.combo_points() >= 5 and ((ctx.is_cast_interruptible and ctx.is_cast_interruptible(ctx.target)) or (ctx.should_cc and ctx.should_cc(ctx.target)))
      end
      return false
    end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(408, ctx.target) end
      return false
    end,
  })
end


