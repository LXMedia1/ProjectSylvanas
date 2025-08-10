-- Wrath (ID: 5176)
-- Balance filler (or general caster filler)
return function(engine)
  engine:register_spell({
    id = 5176,
    name = "Wrath",
    priority = 60,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(5176) then return false end
      if ctx.player and ctx.player.is_moving then
        if ctx.can_cast_while_moving and ctx.can_cast_while_moving(5176) then else return false end
      end
      return true
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(5176, ctx.target) end
      return false
    end,
  })
end


