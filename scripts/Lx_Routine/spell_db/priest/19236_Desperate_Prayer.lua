-- Desperate Prayer (ID: 19236)
-- Self-heal cooldown; use at low HP
return function(engine)
  engine:register_spell({
    id = 19236,
    name = "Desperate Prayer",
    priority = 101,

    is_usable = function(ctx)
      if not ctx or not ctx.get_player then return false end
      local me = ctx.get_player()
      if not me then return false end
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Desperate Prayer") or 19236)) or 19236
      if ctx.can_cast and not ctx.can_cast(sid) then return false end
      return true
    end,

    should_use = function(ctx)
      local me = ctx.get_player and ctx.get_player() or nil
      if not me then return false end
      return (me.health_pct or 100) <= 30
    end,

    execute = function(ctx)
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Desperate Prayer") or 19236)) or 19236
      if ctx.cast_spell then return ctx.cast_spell(sid) end
      return false
    end,
  })
end


