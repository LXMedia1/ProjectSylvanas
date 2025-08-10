-- Frenzied Regeneration (ID: 22842)
-- Guardian self-heal
return function(engine)
  engine:register_spell({
    id = 22842,
    name = "Frenzied Regeneration",
    priority = 150,

    is_usable = function(ctx)
      if not ctx or not ctx.get_player then return false end
      if ctx.can_cast and not ctx.can_cast(22842) then return false end
      if ctx.is_spec and not ctx.is_spec('Guardian') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'guardian') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx)
      local me = ctx.get_player and ctx.get_player() or nil
      if not me then return false end
      return (me.health_pct or 100) <= 50
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(22842) end
      return false
    end,
  })
end


