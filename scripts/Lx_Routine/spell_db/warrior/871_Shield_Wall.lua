-- Shield Wall (ID: 871)
-- Protection major defensive
return function(engine)
  engine:register_spell({
    id = 871,
    name = "Shield Wall",
    priority = 200,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(871) then return false end
      return true
    end,

    should_use = function(ctx)
      local me = ctx.get_player and ctx.get_player() or nil
      if not me then return false end
      local incoming = ctx.expected_damage_in and ctx.expected_damage_in(me, 3.0) or 0
      return (me.health_pct or 100) <= 30 or (incoming and incoming > (me.health_max or 0) * 0.5)
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(871) end
      return false
    end,
  })
end


