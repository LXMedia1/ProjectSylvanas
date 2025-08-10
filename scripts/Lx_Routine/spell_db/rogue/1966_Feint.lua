-- Feint (ID: 1966)
-- AoE damage reduction
return function(engine)
  engine:register_spell({
    id = 1966,
    name = "Feint",
    priority = 140,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(1966) then return false end
      return true
    end,

    should_use = function(ctx)
      local me = ctx.get_player and ctx.get_player() or nil
      if not me then return false end
      local incoming = ctx.expected_damage_in and ctx.expected_damage_in(me, 2.0) or 0
      return (incoming and incoming > (me.health_max or 0) * 0.25)
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(1966) end
      return false
    end,
  })
end


