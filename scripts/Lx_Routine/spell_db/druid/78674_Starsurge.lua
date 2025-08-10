-- Starsurge (ID: 78674)
-- Balance spender
return function(engine)
  engine:register_spell({
    id = 78674,
    name = "Starsurge",
    priority = 90,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(78674) then return false end
      if ctx.is_spec and not ctx.is_spec('Balance') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'balance') and not ctx.is_spec then return false end
      if ctx.player and ctx.player.is_moving then
        if ctx.can_cast_while_moving and ctx.can_cast_while_moving(78674) then else return false end
      end
      return true
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(78674, ctx.target) end
      return false
    end,
  })
end


