-- Mighty Bash (ID: 5211)
-- Stun for control or emergency stop
return function(engine)
  engine:register_spell({
    id = 5211,
    name = "Mighty Bash",
    priority = 110,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(5211) then return false end
      if ctx.is_cast_interruptible and ctx.is_cast_interruptible(ctx.target) then return true end
      if ctx.should_cc and ctx.should_cc(ctx.target) then return true end
      return false
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(5211, ctx.target) end
      return false
    end,
  })
end


