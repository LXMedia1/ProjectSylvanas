-- Havoc (ID: 80240)
-- Destruction cleave debuff
return function(engine)
  engine:register_spell({
    id = 80240,
    name = "Havoc",
    priority = 85,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(80240) then return false end
      if ctx.is_spec and not ctx.is_spec('Destruction') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'destruction') and not ctx.is_spec then return false end
      local n = ctx.enemies_close and ctx.enemies_close(15) or 0
      return n >= 2
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(80240, ctx.target) end
      return false
    end,
  })
end


