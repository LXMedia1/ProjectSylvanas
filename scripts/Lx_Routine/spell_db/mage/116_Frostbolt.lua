-- Frostbolt (ID: 116)
return function(engine)
  engine:register_spell({
    id = 116,
    name = "Frostbolt",
    priority = 55,
    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.target.is_dead or not ctx.target.is_enemy then return false end
      if ctx.can_cast and not ctx.can_cast(116) then return false end
      if ctx.player and ctx.player.is_moving then
        if ctx.can_cast_while_moving and ctx.can_cast_while_moving(116) then else return false end
      end
      return true
    end,
    should_use = function(ctx) return true end,
    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(116, ctx.target) end
      return false
    end,
  })
end


