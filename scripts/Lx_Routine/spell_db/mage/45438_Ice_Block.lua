-- Ice Block (ID: 45438)
-- Emergency immunity; use to survive lethal damage
return function(engine)
  engine:register_spell({
    id = 45438,
    name = "Ice Block",
    priority = 200,

    is_usable = function(ctx)
      if not ctx or not ctx.get_player then return false end
      if ctx.can_cast and not ctx.can_cast(45438) then return false end
      local me = ctx.get_player()
      return me ~= nil
    end,

    should_use = function(ctx)
      local me = ctx.get_player and ctx.get_player() or nil
      if not me then return false end
      local incoming = ctx.expected_damage_in and ctx.expected_damage_in(me, 2.0) or 0
      return (me.health_pct or 100) <= 20 or (incoming and incoming > (me.health_max or 0) * 0.4)
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(45438) end
      return false
    end,
  })
end


