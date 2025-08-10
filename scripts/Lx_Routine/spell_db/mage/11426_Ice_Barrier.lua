-- Ice Barrier (ID: 11426)
-- Frost defensive; pre-mitigate incoming damage
return function(engine)
  engine:register_spell({
    id = 11426,
    name = "Ice Barrier",
    priority = 120,

    is_usable = function(ctx)
      if not ctx or not ctx.get_player then return false end
      if ctx.can_cast and not ctx.can_cast(11426) then return false end
      if ctx.is_spec and not ctx.is_spec('Frost') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'frost') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx)
      local me = ctx.get_player and ctx.get_player() or nil
      if not me then return false end
      if ctx.has_buff and ctx.has_buff(me, 11426) then return false end
      local incoming = ctx.expected_damage_in and ctx.expected_damage_in(me, 3.0) or 0
      return incoming and incoming > (me.health_max or 0) * 0.2
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(11426) end
      return false
    end,
  })
end


