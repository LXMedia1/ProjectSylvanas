-- Hammer of Justice (ID: 853)
-- Single target stun; use for dangerous casts if no interrupt or as control
return function(engine)
  engine:register_spell({
    id = 853,
    name = "Hammer of Justice",
    priority = 110,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(853) then return false end
      if ctx.is_cast_interruptible and ctx.is_cast_interruptible(ctx.target) then
        -- if we cannot kick, use stun
        if not (ctx.can_cast and ctx.can_cast(96231)) then return true end
      end
      if ctx.should_cc and ctx.should_cc(ctx.target) then return true end
      return false
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(853, ctx.target) end
      return false
    end,
  })
end


