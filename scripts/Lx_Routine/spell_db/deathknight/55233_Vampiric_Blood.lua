-- Vampiric Blood (ID: 55233)
-- Blood defensive cooldown
return function(engine)
  engine:register_spell({
    id = 55233,
    name = "Vampiric Blood",
    priority = 190,

    is_usable = function(ctx)
      if not ctx or not ctx.get_player then return false end
      if ctx.can_cast and not ctx.can_cast(55233) then return false end
      return true
    end,

    should_use = function(ctx)
      local me = ctx.get_player and ctx.get_player() or nil
      if not me then return false end
      local incoming = ctx.expected_damage_in and ctx.expected_damage_in(me, 3.0) or 0
      return (me.health_pct or 100) <= 35 or (incoming and incoming > (me.health_max or 0) * 0.45)
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(55233) end
      return false
    end,
  })
end


