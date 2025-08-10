-- Crimson Tempest (ID: 121411)
-- AoE bleed finisher
return function(engine)
  engine:register_spell({
    id = 121411,
    name = "Crimson Tempest",
    priority = 85,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(121411) then return false end
      local n = ctx.enemies_close and ctx.enemies_close(8) or 0
      return n >= 3
    end,

    should_use = function(ctx)
      return ctx.combo_points and ctx.combo_points() and ctx.combo_points() >= 5
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(121411) end
      return false
    end,
  })
end



