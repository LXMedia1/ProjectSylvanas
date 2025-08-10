-- Divine Shield (ID: 642)
-- Immunity; use to survive lethal damage
return function(engine)
  engine:register_spell({
    id = 642,
    name = "Divine Shield",
    priority = 210,

    is_usable = function(ctx)
      if not ctx or not ctx.get_player then return false end
      if ctx.can_cast and not ctx.can_cast(642) then return false end
      return true
    end,

    should_use = function(ctx)
      local me = ctx.get_player and ctx.get_player() or nil
      if not me then return false end
      local incoming = ctx.expected_damage_in and ctx.expected_damage_in(me, 2.0) or 0
      return (me.health_pct or 100) <= 10 or (incoming and incoming > (me.health_max or 0) * 0.6)
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(642) end
      return false
    end,
  })
end


