-- Holy Word: Serenity (ID: 2050)
-- Big single-target heal; use when someone is very low
return function(engine)
  engine:register_spell({
    id = 2050,
    name = "Holy Word: Serenity",
    priority = 102,

    is_usable = function(ctx)
      if not ctx then return false end
      local ally = (ctx.get_ally_critical and ctx.get_ally_critical()) or (ctx.get_ally_lowest and ctx.get_ally_lowest())
      if not ally then return false end
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Holy Word: Serenity") or 2050)) or 2050
      if ctx.can_cast and not ctx.can_cast(sid) then return false end
      return true
    end,

    should_use = function(ctx)
      local ally = (ctx.get_ally_critical and ctx.get_ally_critical()) or (ctx.get_ally_lowest and ctx.get_ally_lowest())
      if not ally then return false end
      return (ally.health_pct or 100) <= 35
    end,

    execute = function(ctx)
      local ally = (ctx.get_ally_critical and ctx.get_ally_critical()) or (ctx.get_ally_lowest and ctx.get_ally_lowest())
      if ally and ctx.cast_spell_on then
        local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Holy Word: Serenity") or 2050)) or 2050
        return ctx.cast_spell_on(sid, ally)
      end
      return false
    end,
  })
end


