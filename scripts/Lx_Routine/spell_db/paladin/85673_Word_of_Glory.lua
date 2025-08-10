-- Word of Glory (ID: 85673)
-- Instant heal spender; use on low allies/self
return function(engine)
  engine:register_spell({
    id = 85673,
    name = "Word of Glory",
    priority = 118,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(85673) then return false end
      return true
    end,

    should_use = function(ctx)
      local ally = (ctx.get_ally_critical and ctx.get_ally_critical()) or (ctx.get_player and ctx.get_player())
      if not ally then return false end
      return (ally.health_pct or 100) <= 35
    end,

    execute = function(ctx)
      local ally = (ctx.get_ally_critical and ctx.get_ally_critical()) or (ctx.get_player and ctx.get_player())
      if ally and ctx.cast_spell_on then return ctx.cast_spell_on(85673, ally) end
      return false
    end,
  })
end


