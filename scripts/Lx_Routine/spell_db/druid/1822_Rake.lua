-- Rake (ID: 1822)
-- Feral bleed and stun from stealth (not handled here)
return function(engine)
  engine:register_spell({
    id = 1822,
    name = "Rake",
    priority = 92,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id('Rake') or 1822)) or 1822
      if ctx.can_cast and not ctx.can_cast(sid) then return false end
      if ctx.is_spec and not ctx.is_spec('Feral') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'feral') and not ctx.is_spec then return false end
      local d = ctx.distance_to and ctx.distance_to(ctx.target)
      return d and d <= 5
    end,

    should_use = function(ctx)
      if ctx.aura_remaining then
        local remain = ctx.aura_remaining(ctx.target, 155722) -- Rake bleed aura
        return (not remain) or remain <= 3.0
      end
      if ctx.has_debuff then return not ctx.has_debuff(ctx.target, 155722) end
      return true
    end,

    execute = function(ctx)
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id('Rake') or 1822)) or 1822
      if ctx.cast_spell_on then return ctx.cast_spell_on(sid, ctx.target) end
      return false
    end,
  })
end


