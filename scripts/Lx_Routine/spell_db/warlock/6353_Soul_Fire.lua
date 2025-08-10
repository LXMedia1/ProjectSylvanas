-- Soul Fire (ID: 6353)
-- Destruction nuke
return function(engine)
  engine:register_spell({
    id = 6353,
    name = "Soul Fire",
    priority = 88,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(6353) then return false end
      if ctx.is_spec and not ctx.is_spec('Destruction') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'destruction') and not ctx.is_spec then return false end
      if ctx.player and ctx.player.is_moving then
        if ctx.can_cast_while_moving and ctx.can_cast_while_moving(6353) then else return false end
      end
      return true
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(6353, ctx.target) end
      return false
    end,
  })
end


