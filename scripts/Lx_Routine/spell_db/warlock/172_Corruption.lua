-- Corruption (ID: 172)
-- Affliction DoT
return function(engine)
  engine:register_spell({
    id = 172,
    name = "Corruption",
    priority = 92,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(172) then return false end
      if ctx.is_spec and not ctx.is_spec('Affliction') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'affliction') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx)
      if ctx.aura_remaining then
        local remain = ctx.aura_remaining(ctx.target, 172)
        return (not remain) or remain <= 3.0
      end
      if ctx.has_debuff then return not ctx.has_debuff(ctx.target, 172) end
      return true
    end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(172, ctx.target) end
      return false
    end,
  })
end


