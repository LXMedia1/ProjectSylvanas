-- Repentance (ID: 20066)
-- Crowd control
return function(engine)
  engine:register_spell({
    id = 20066,
    name = "Repentance",
    priority = 65,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(20066) then return false end
      if ctx.should_cc and ctx.should_cc(ctx.target) then return true end
      return false
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(20066, ctx.target) end
      return false
    end,
  })
end


