-- Void Eruption (ID: 228260)
-- Shadow cooldown to enter Voidform; use in combat when DoTs are applied
return function(engine)
  engine:register_spell({
    id = 228260,
    name = "Void Eruption",
    priority = 100,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.target.is_dead or not ctx.target.is_enemy then return false end
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Void Eruption") or 228260)) or 228260
      if ctx.can_cast and not ctx.can_cast(sid) then return false end
      return true
    end,

    should_use = function(ctx)
      if ctx.aura_remaining then
        local vt = ctx.aura_remaining(ctx.target, 34914)
        local swp = ctx.aura_remaining(ctx.target, 589)
        return (vt and vt > 4) and (swp and swp > 4)
      end
      return true
    end,

    execute = function(ctx)
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Void Eruption") or 228260)) or 228260
      if ctx.cast_spell then return ctx.cast_spell(sid) end
      return false
    end,
  })
end


