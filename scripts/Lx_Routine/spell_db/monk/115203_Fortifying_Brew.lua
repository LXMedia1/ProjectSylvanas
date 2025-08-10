-- Fortifying Brew (ID: 115203)
-- Monk major defensive
return function(engine)
  engine:register_spell({
    id = 115203,
    name = "Fortifying Brew",
    priority = 200,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(115203) then return false end
      return true
    end,

    should_use = function(ctx)
      local me = ctx.get_player and ctx.get_player() or nil
      if not me then return false end
      local incoming = ctx.expected_damage_in and ctx.expected_damage_in(me, 3.0) or 0
      return (me.health_pct or 100) <= 25 or (incoming and incoming > (me.health_max or 0) * 0.5)
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(115203) end
      return false
    end,
  })
end


