-- Judgment (ID: 20271)
-- Core ranged holy strike; used by all specs
return function(engine)
  engine:register_spell({
    id = 20271,
    name = "Judgment",
    priority = 80,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.target.is_dead or not ctx.target.is_enemy then return false end
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Judgment") or 20271)) or 20271
      if ctx.can_cast and not ctx.can_cast(sid) then return false end
      if ctx.is_in_range and not ctx.is_in_range(sid, ctx.target) then return false end
      return true
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Judgment") or 20271)) or 20271
      if ctx.cast_spell_on then return ctx.cast_spell_on(sid, ctx.target) end
      return false
    end,
  })
end


