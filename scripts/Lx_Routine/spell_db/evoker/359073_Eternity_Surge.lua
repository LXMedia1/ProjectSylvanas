-- Eternity Surge (ID: 359073)
-- Devastation empowered nuke (baseline cast here)
return function(engine)
  engine:register_spell({
    id = 359073,
    name = "Eternity Surge",
    priority = 99,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(359073) then return false end
      if ctx.is_spec and not ctx.is_spec('Devastation') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'devastation') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(359073, ctx.target) end
      return false
    end,
  })
end


