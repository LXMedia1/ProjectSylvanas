-- Hand of Reckoning (ID: 62124)
-- Paladin taunt
return function(engine)
  engine:register_spell({
    id = 62124,
    name = "Hand of Reckoning",
    priority = 110,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(62124) then return false end
      if ctx.should_taunt and not ctx.should_taunt(ctx.target) then return false end
      return true
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(62124, ctx.target) end
      return false
    end,
  })
end


