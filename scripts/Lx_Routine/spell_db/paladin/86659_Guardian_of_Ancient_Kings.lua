-- Guardian of Ancient Kings (ID: 86659)
-- Major defensive cooldown
return function(engine)
  engine:register_spell({
    id = 86659,
    name = "Guardian of Ancient Kings",
    priority = 205,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(86659) then return false end
      return true
    end,

    should_use = function(ctx)
      local me = ctx.get_player and ctx.get_player() or nil
      if not me then return false end
      local incoming = ctx.expected_damage_in and ctx.expected_damage_in(me, 3.0) or 0
      return (me.health_pct or 100) <= 20 or (incoming and incoming > (me.health_max or 0) * 0.5)
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(86659) end
      return false
    end,
  })
end


