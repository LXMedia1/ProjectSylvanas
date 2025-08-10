-- Lay on Hands (ID: 633)
-- Big emergency heal
return function(engine)
  engine:register_spell({
    id = 633,
    name = "Lay on Hands",
    priority = 200,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(633) then return false end
      local ally = (ctx.get_ally_critical and ctx.get_ally_critical()) or (ctx.get_player and ctx.get_player())
      return ally ~= nil
    end,

    should_use = function(ctx)
      local ally = (ctx.get_ally_critical and ctx.get_ally_critical()) or (ctx.get_player and ctx.get_player())
      if not ally then return false end
      return (ally.health_pct or 100) <= 15
    end,

    execute = function(ctx)
      local ally = (ctx.get_ally_critical and ctx.get_ally_critical()) or (ctx.get_player and ctx.get_player())
      if ally and ctx.cast_spell_on then return ctx.cast_spell_on(633, ally) end
      return false
    end,
  })
end


