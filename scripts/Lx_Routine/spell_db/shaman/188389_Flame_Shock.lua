-- Flame Shock (ID approx: 188389 aura; resolve by name preferred)
return function(engine)
  engine:register_spell({
    id = 188389,
    name = "Flame Shock",
    priority = 95,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Flame Shock") or 188389)) or 188389
      if ctx.can_cast and not ctx.can_cast(sid) then return false end
      if ctx.is_spec and not ctx.is_spec('Elemental') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'elemental') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx)
      if ctx.aura_remaining then
        local remain = ctx.aura_remaining(ctx.target, 188389)
        return (not remain) or remain <= 4.0
      end
      if ctx.has_debuff then return not ctx.has_debuff(ctx.target, 188389) end
      return true
    end,

    execute = function(ctx)
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Flame Shock") or 188389)) or 188389
      if ctx.cast_spell_on then return ctx.cast_spell_on(sid, ctx.target) end
      return false
    end,
  })
end


