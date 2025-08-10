-- Crash Lightning (ID: 187874)
-- Enhancement AoE
return function(engine)
  engine:register_spell({
    id = 187874,
    name = "Crash Lightning",
    priority = 80,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(187874) then return false end
      if ctx.is_spec and not ctx.is_spec('Enhancement') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'enhancement') and not ctx.is_spec then return false end
      local n = ctx.enemies_close and ctx.enemies_close(8) or 0
      return n >= 2
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(187874) end
      return false
    end,
  })
end


