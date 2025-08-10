-- Arcane Blast (ID: 30451)
-- Arcane primary nuke
return function(engine)
  engine:register_spell({
    id = 30451,
    name = "Arcane Blast",
    priority = 80,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.target.is_dead or not ctx.target.is_enemy then return false end
      if ctx.can_cast and not ctx.can_cast(30451) then return false end
      if ctx.player and ctx.player.is_moving then
        if ctx.can_cast_while_moving and ctx.can_cast_while_moving(30451) then else return false end
      end
      return true
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(30451, ctx.target) end
      return false
    end,
  })
end


