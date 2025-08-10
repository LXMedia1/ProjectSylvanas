-- Crimson Vial (ID: 185311)
-- Self-heal
return function(engine)
  engine:register_spell({
    id = 185311,
    name = "Crimson Vial",
    priority = 150,

    is_usable = function(ctx)
      if not ctx or not ctx.get_player then return false end
      if ctx.can_cast and not ctx.can_cast(185311) then return false end
      return true
    end,

    should_use = function(ctx)
      local me = ctx.get_player and ctx.get_player() or nil
      if not me then return false end
      return (me.health_pct or 100) <= 50
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(185311) end
      return false
    end,
  })
end


