-- Cheap Shot (ID: 1833)
-- Stun from stealth
return function(engine)
  engine:register_spell({
    id = 1833,
    name = "Cheap Shot",
    priority = 112,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(1833) then return false end
      return true
    end,

    should_use = function(ctx)
      return ctx.is_stealthed and ctx.is_stealthed()
    end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(1833, ctx.target) end
      return false
    end,
  })
end


