-- Mind Sear (ID: 48045)
-- Shadow AoE channel; prefer when multiple enemies
return function(engine)
  engine:register_spell({
    id = 48045,
    name = "Mind Sear",
    priority = 94,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.target.is_dead or not ctx.target.is_enemy then return false end
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Mind Sear") or 48045)) or 48045
      if ctx.can_cast and not ctx.can_cast(sid) then return false end
      local n = ctx.enemies_around_target and ctx.enemies_around_target(ctx.target, 10) or (ctx.enemies_close and ctx.enemies_close(10) or 0)
      if n < 3 then return false end
      if ctx.player and ctx.player.is_moving then
        if ctx.can_cast_while_moving and ctx.can_cast_while_moving(sid) then else return false end
      end
      return true
    end,

    should_use = function(ctx)
      return true
    end,

    execute = function(ctx)
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Mind Sear") or 48045)) or 48045
      if ctx.cast_spell_on and ctx.target then
        return ctx.cast_spell_on(sid, ctx.target)
      end
      return false
    end,
  })
end


