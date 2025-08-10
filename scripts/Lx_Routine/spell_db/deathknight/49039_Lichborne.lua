-- Lichborne (ID: 49039)
-- DK defensive utility
return function(engine)
  engine:register_spell({
    id = 49039,
    name = "Lichborne",
    priority = 150,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(49039) then return false end
      return true
    end,

    should_use = function(ctx)
      local me = ctx.get_player and ctx.get_player() or nil
      return me and ((me.health_pct or 100) <= 40)
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(49039) end
      return false
    end,
  })
end


