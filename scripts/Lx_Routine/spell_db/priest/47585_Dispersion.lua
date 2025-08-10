-- Dispersion (ID: 47585)
-- Shadow defensive; use to survive lethal damage
return function(engine)
  engine:register_spell({
    id = 47585,
    name = "Dispersion",
    priority = 110,

    is_usable = function(ctx)
      if not ctx or not ctx.get_player then return false end
      if ctx.can_cast and not ctx.can_cast(47585) then return false end
      local me = ctx.get_player()
      return me ~= nil
    end,

    should_use = function(ctx)
      local me = ctx.get_player and ctx.get_player() or nil
      if not me then return false end
      local incoming = ctx.expected_damage_in and ctx.expected_damage_in(me, 2.0) or 0
      return (me.health_pct or 100) <= 25 or (incoming and incoming > 0 and incoming > (me.health_max or 0) * 0.3)
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(47585) end
      return false
    end,
  })
end


