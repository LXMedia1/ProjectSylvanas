-- Fiery Brand (ID: 204021)
-- Vengeance major defensive
return function(engine)
  engine:register_spell({
    id = 204021,
    name = "Fiery Brand",
    priority = 190,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(204021) then return false end
      return true
    end,

    should_use = function(ctx)
      local me = ctx.get_player and ctx.get_player() or nil
      local incoming = ctx.expected_damage_in and ctx.expected_damage_in(me, 3.0) or 0
      return me and ((me.health_pct or 100) <= 35 or (incoming and incoming > (me.health_max or 0) * 0.5))
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(204021) end
      return false
    end,
  })
end


