-- Rapture (ID: 47536)
-- Disc cooldown to empower shielding during heavy damage
return function(engine)
  engine:register_spell({
    id = 47536,
    name = "Rapture",
    priority = 103,

    is_usable = function(ctx)
      if not ctx then return false end
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Rapture") or 47536)) or 47536
      if ctx.can_cast and not ctx.can_cast(sid) then return false end
      local injured = ctx.count_allies_below and ctx.count_allies_below(85) or 0
      return injured >= 4
    end,

    should_use = function(ctx)
      return true
    end,

    execute = function(ctx)
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Rapture") or 47536)) or 47536
      if ctx.cast_spell then return ctx.cast_spell(sid) end
      return false
    end,
  })
end


