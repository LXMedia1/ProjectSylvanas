-- Frozen Orb (ID: 84714)
-- Frost AoE/CD; use on pack or on cooldown depending on spec guidance
return function(engine)
  engine:register_spell({
    id = 84714,
    name = "Frozen Orb",
    priority = 90,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(84714) then return false end
      if ctx.is_spec and not ctx.is_spec('Frost') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'frost') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx)
      local n = ctx.enemies_close and ctx.enemies_close(10) or 0
      return n >= 2
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(84714) end
      return false
    end,
  })
end


