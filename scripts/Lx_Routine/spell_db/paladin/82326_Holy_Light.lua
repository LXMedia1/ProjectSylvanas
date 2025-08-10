-- Holy Light (ID: 82326)
-- Efficient heal
return function(engine)
  engine:register_spell({
    id = 82326,
    name = "Holy Light",
    priority = 90,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(82326) then return false end
      local ally = (ctx.get_ally_lowest and ctx.get_ally_lowest()) or (ctx.get_player and ctx.get_player())
      return ally ~= nil
    end,

    should_use = function(ctx)
      local ally = (ctx.get_ally_lowest and ctx.get_ally_lowest()) or (ctx.get_player and ctx.get_player())
      if not ally then return false end
      local hp = ally.health_pct or 100
      return hp <= 80 and hp > 50
    end,

    execute = function(ctx)
      local ally = (ctx.get_ally_lowest and ctx.get_ally_lowest()) or (ctx.get_player and ctx.get_player())
      if ally and ctx.cast_spell_on then return ctx.cast_spell_on(82326, ally) end
      return false
    end,
  })
end


