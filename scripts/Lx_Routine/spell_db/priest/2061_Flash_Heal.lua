-- Flash Heal (ID: 2061)
-- Fast expensive heal; use for emergencies.
return function(engine)
  engine:register_spell({
    id = 2061,
    name = "Flash Heal",
    priority = 92,

    is_usable = function(ctx)
      if not ctx or (ctx.can_cast and not ctx.can_cast(2061)) then return false end
      local ally = (ctx.get_ally_lowest and ctx.get_ally_lowest()) or (ctx.get_player and ctx.get_player())
      if not ally then return false end
      return true
    end,

    should_use = function(ctx)
      local ally = (ctx.get_ally_lowest and ctx.get_ally_lowest()) or (ctx.get_player and ctx.get_player())
      if not ally then return false end
      local hp = ally.health_pct or 100
      return hp <= 50
    end,

    execute = function(ctx)
      local ally = (ctx.get_ally_lowest and ctx.get_ally_lowest()) or (ctx.get_player and ctx.get_player())
      if ally and ctx.cast_spell_on then
        return ctx.cast_spell_on(2061, ally)
      end
      return false
    end,
  })
end


