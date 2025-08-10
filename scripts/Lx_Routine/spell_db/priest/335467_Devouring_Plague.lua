-- Devouring Plague (ID: 335467)
-- Shadow Insanity spender; maintain uptime, avoid overcapping
return function(engine)
  engine:register_spell({
    id = 335467,
    name = "Devouring Plague",
    priority = 97,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.target.is_dead or not ctx.target.is_enemy then return false end
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Devouring Plague") or 335467)) or 335467
      if ctx.can_cast and not ctx.can_cast(sid) then return false end
      return true
    end,

    should_use = function(ctx)
      if ctx.aura_remaining then
        local remain = ctx.aura_remaining(ctx.target, 335467)
        if remain and remain > 2.0 then return false end
      elseif ctx.has_debuff and ctx.has_debuff(ctx.target, 335467) then
        return false
      end
      return true
    end,

    execute = function(ctx)
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Devouring Plague") or 335467)) or 335467
      if ctx.cast_spell_on and ctx.target then
        return ctx.cast_spell_on(sid, ctx.target)
      end
      return false
    end,
  })
end


