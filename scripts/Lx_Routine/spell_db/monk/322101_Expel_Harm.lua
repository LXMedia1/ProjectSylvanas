-- Expel Harm (ID: 322101)
-- Self heal and damage
return function(engine)
  engine:register_spell({
    id = 322101,
    name = "Expel Harm",
    priority = 140,

    is_usable = function(ctx)
      if not ctx or not ctx.get_player then return false end
      if ctx.can_cast and not ctx.can_cast(322101) then return false end
      return true
    end,

    should_use = function(ctx)
      local me = ctx.get_player and ctx.get_player() or nil
      if not me then return false end
      return (me.health_pct or 100) <= 70
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(322101) end
      return false
    end,
  })
end


