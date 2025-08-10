-- Silence (ID: 15487)
-- Shadow interrupt; use on interruptible casts
return function(engine)
  engine:register_spell({
    id = 15487,
    name = "Silence",
    priority = 120,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Silence") or 15487)) or 15487
      if ctx.can_cast and not ctx.can_cast(sid) then return false end
      if ctx.is_cast_interruptible then
        return ctx.is_cast_interruptible(ctx.target)
      end
      return false
    end,

    should_use = function(ctx)
      return true
    end,

    execute = function(ctx)
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Silence") or 15487)) or 15487
      if ctx.cast_spell_on and ctx.target then
        return ctx.cast_spell_on(sid, ctx.target)
      end
      return false
    end,
  })
end


