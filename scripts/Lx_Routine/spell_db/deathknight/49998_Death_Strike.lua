-- Death Strike (ID: 49998)
-- Self-heal on recent damage; Blood core and DK defensive heal
return function(engine)
  engine:register_spell({
    id = 49998,
    name = "Death Strike",
    priority = 150,

    is_usable = function(ctx)
      if not ctx or not ctx.get_player then return false end
      if ctx.can_cast and not ctx.can_cast(49998) then return false end
      return true
    end,

    should_use = function(ctx)
      local me = ctx.get_player and ctx.get_player() or nil
      if not me then return false end
      local incoming = ctx.expected_damage_in and ctx.expected_damage_in(me, 3.0) or 0
      return (me.health_pct or 100) <= 50 or (incoming and incoming > (me.health_max or 0) * 0.3)
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(49998) end
      return false
    end,
  })
end


