-- Aimed Shot (ID: 19434)
-- Marksmanship hard hitter
return function(engine)
  engine:register_spell({
    id = 19434,
    name = "Aimed Shot",
    priority = 90,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(19434) then return false end
      if ctx.is_spec and not ctx.is_spec('Marksmanship') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'marksmanship') and not ctx.is_spec then return false end
      if ctx.player and ctx.player.is_moving then
        if ctx.can_cast_while_moving and ctx.can_cast_while_moving(19434) then else return false end
      end
      return true
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(19434, ctx.target) end
      return false
    end,
  })
end


