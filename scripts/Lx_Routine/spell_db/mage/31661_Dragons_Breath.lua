-- Dragon's Breath (ID: 31661)
-- Cone disorient; use as AoE stop/control or setup
return function(engine)
  engine:register_spell({
    id = 31661,
    name = "Dragon's Breath",
    priority = 95,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(31661) then return false end
      if ctx.is_spec and not ctx.is_spec('Fire') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'fire') and not ctx.is_spec then return false end
      local n = ctx.enemies_close and ctx.enemies_close(10) or 0
      return n >= 2
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(31661) end
      return false
    end,
  })
end


