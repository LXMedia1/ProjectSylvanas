-- Shield of Vengeance (ID: 184662)
-- Ret defensive absorb
return function(engine)
  engine:register_spell({
    id = 184662,
    name = "Shield of Vengeance",
    priority = 150,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(184662) then return false end
      if ctx.is_spec and not ctx.is_spec('Retribution') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'retribution') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx)
      local me = ctx.get_player and ctx.get_player() or nil
      if not me then return false end
      local incoming = ctx.expected_damage_in and ctx.expected_damage_in(me, 2.0) or 0
      return (me.health_pct or 100) <= 40 or (incoming and incoming > (me.health_max or 0) * 0.3)
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(184662) end
      return false
    end,
  })
end


