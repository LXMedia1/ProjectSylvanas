-- Blessing of Freedom (ID: 1044)
-- Movement freedom for ally/self
return function(engine)
  engine:register_spell({
    id = 1044,
    name = "Blessing of Freedom",
    priority = 140,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(1044) then return false end
      local ally = (ctx.get_ally_urgent and ctx.get_ally_urgent()) or (ctx.get_player and ctx.get_player())
      return ally ~= nil
    end,

    should_use = function(ctx)
      local ally = (ctx.get_ally_urgent and ctx.get_ally_urgent()) or (ctx.get_player and ctx.get_player())
      if not ally then return false end
      return ctx.is_rooted_or_slowed and ctx.is_rooted_or_slowed(ally)
    end,

    execute = function(ctx)
      local ally = (ctx.get_ally_urgent and ctx.get_ally_urgent()) or (ctx.get_player and ctx.get_player())
      if ally and ctx.cast_spell_on then return ctx.cast_spell_on(1044, ally) end
      return false
    end,
  })
end


