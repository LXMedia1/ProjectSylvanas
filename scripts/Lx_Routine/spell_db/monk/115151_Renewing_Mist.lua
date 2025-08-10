-- Renewing Mist (ID: 115151)
-- Mistweaver HoT
return function(engine)
  engine:register_spell({
    id = 115151,
    name = "Renewing Mist",
    priority = 95,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(115151) then return false end
      return true
    end,

    should_use = function(ctx)
      local ally = (ctx.get_ally_lowest and ctx.get_ally_lowest()) or (ctx.get_player and ctx.get_player())
      if not ally then return false end
      if ctx.has_buff and ctx.has_buff(ally, 115151) then return false end
      return (ally.health_pct or 100) < 95
    end,

    execute = function(ctx)
      local ally = (ctx.get_ally_lowest and ctx.get_ally_lowest()) or (ctx.get_player and ctx.get_player())
      if ally and ctx.cast_spell_on then return ctx.cast_spell_on(115151, ally) end
      return false
    end,
  })
end


