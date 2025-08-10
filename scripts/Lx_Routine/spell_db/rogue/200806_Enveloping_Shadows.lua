-- Enveloping Shadows (ID: 206237/200806 varies by rank/talent)
-- Subtlety defensive/buff – placeholder gating by spec
return function(engine)
  engine:register_spell({
    id = 200806,
    name = "Enveloping Shadows",
    priority = 130,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(200806) then return false end
      if ctx.is_spec and not ctx.is_spec('Subtlety') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'subtlety') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx)
      local me = ctx.get_player and ctx.get_player() or nil
      if not me then return false end
      local incoming = ctx.expected_damage_in and ctx.expected_damage_in(me, 2.0) or 0
      return incoming and incoming > (me.health_max or 0) * 0.25
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(200806) end
      return false
    end,
  })
end


