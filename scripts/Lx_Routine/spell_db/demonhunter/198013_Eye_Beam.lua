-- Eye Beam (ID: 198013)
-- Havoc channel; high AoE/priority
return function(engine)
  engine:register_spell({
    id = 198013,
    name = "Eye Beam",
    priority = 98,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(198013) then return false end
      if ctx.player and ctx.player.is_moving then
        if ctx.can_cast_while_moving and ctx.can_cast_while_moving(198013) then else return false end
      end
      return true
    end,

    should_use = function(ctx)
      local n = ctx.enemies_close and ctx.enemies_close(10) or 0
      return n >= 2
    end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(198013, ctx.target) end
      return false
    end,
  })
end


