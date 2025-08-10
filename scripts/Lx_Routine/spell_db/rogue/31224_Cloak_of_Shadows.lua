-- Cloak of Shadows (ID: 31224)
-- Magic immunity defensive
return function(engine)
  engine:register_spell({
    id = 31224,
    name = "Cloak of Shadows",
    priority = 180,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(31224) then return false end
      return true
    end,

    should_use = function(ctx)
      local me = ctx.get_player and ctx.get_player() or nil
      if not me then return false end
      local incoming = ctx.expected_damage_in and ctx.expected_damage_in(me, 2.0) or 0
      return (me.health_pct or 100) <= 25 or (incoming and incoming > (me.health_max or 0) * 0.35)
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(31224) end
      return false
    end,
  })
end


