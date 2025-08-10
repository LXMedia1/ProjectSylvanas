-- Howling Blast (ID: 49184)
-- Frost ranged AoE/DoT applicator
return function(engine)
  engine:register_spell({
    id = 49184,
    name = "Howling Blast",
    priority = 92,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(49184) then return false end
      if ctx.is_spec and not ctx.is_spec('Frost') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'frost') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx)
      local n = ctx.enemies_close and ctx.enemies_close(10) or 0
      return n >= 2
    end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(49184, ctx.target) end
      return false
    end,
  })
end


