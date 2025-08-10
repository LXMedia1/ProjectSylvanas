-- Living Flame (ID: 369459)
-- Devastation/Perservation versatile spell (damage or heal)
return function(engine)
  engine:register_spell({
    id = 369459,
    name = "Living Flame",
    priority = 70,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(369459) then return false end
      return true
    end,

    should_use = function(ctx)
      local ally = ctx.get_ally_urgent and ctx.get_ally_urgent()
      if ally and ((ally.health_pct or 100) <= 60) then return true end
      return ctx.target and ctx.target.is_enemy and not ctx.target.is_dead
    end,

    execute = function(ctx)
      local ally = ctx.get_ally_urgent and ctx.get_ally_urgent()
      if ally and ctx.cast_spell_on then return ctx.cast_spell_on(369459, ally) end
      if ctx.target and ctx.cast_spell_on then return ctx.cast_spell_on(369459, ctx.target) end
      return false
    end,
  })
end


