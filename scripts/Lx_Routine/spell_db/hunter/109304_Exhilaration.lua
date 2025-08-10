-- Exhilaration (ID: 109304)
-- Self-heal cooldown
return function(engine)
  engine:register_spell({
    id = 109304,
    name = "Exhilaration",
    priority = 150,

    is_usable = function(ctx)
      if not ctx or not ctx.get_player then return false end
      if ctx.can_cast and not ctx.can_cast(109304) then return false end
      return true
    end,

    should_use = function(ctx)
      local me = ctx.get_player and ctx.get_player() or nil
      if not me then return false end
      return (me.health_pct or 100) <= 40
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(109304) end
      return false
    end,
  })
end


