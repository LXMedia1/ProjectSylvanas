-- Mass Dispel (ID: 32375)
-- AoE dispel; optional ground targeting support
return function(engine)
  engine:register_spell({
    id = 32375,
    name = "Mass Dispel",
    priority = 91,

    is_usable = function(ctx)
      if not ctx then return false end
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Mass Dispel") or 32375)) or 32375
      if ctx.can_cast and not ctx.can_cast(sid) then return false end
      if ctx.count_allies_dispellable and ctx.count_allies_dispellable() >= 3 then return true end
      if ctx.count_enemies_dispellable and ctx.count_enemies_dispellable() >= 2 then return true end
      return false
    end,

    should_use = function(ctx)
      return true
    end,

    execute = function(ctx)
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Mass Dispel") or 32375)) or 32375
      if ctx.cast_spell then return ctx.cast_spell(sid) end
      return false
    end,
  })
end


