-- Sunfire (ID: 93402)
-- Balance DoT
return function(engine)
  engine:register_spell({
    id = 93402,
    name = "Sunfire",
    priority = 82,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id('Sunfire') or 93402)) or 93402
      if ctx.can_cast and not ctx.can_cast(sid) then return false end
      if ctx.is_spec and not ctx.is_spec('Balance') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'balance') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx)
      if ctx.aura_remaining then
        local remain = ctx.aura_remaining(ctx.target, 164815) -- Sunfire debuff aura
        return (not remain) or remain <= 3.0
      end
      if ctx.has_debuff then return not ctx.has_debuff(ctx.target, 164815) end
      return true
    end,

    execute = function(ctx)
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id('Sunfire') or 93402)) or 93402
      if ctx.cast_spell_on then return ctx.cast_spell_on(sid, ctx.target) end
      return false
    end,
  })
end


