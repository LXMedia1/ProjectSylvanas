-- Cobra Shot (ID: 193455)
-- BM focus dump
return function(engine)
  engine:register_spell({
    id = 193455,
    name = "Cobra Shot",
    priority = 60,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(193455) then return false end
      if ctx.is_spec and not ctx.is_spec('Beast Mastery') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'beast mastery') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(193455, ctx.target) end
      return false
    end,
  })
end


