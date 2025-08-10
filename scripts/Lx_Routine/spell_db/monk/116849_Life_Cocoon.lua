-- Life Cocoon (ID: 116849)
-- Mistweaver external
return function(engine)
  engine:register_spell({
    id = 116849,
    name = "Life Cocoon",
    priority = 170,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(116849) then return false end
      return true
    end,

    should_use = function(ctx)
      local ally = (ctx.get_tank_urgent and ctx.get_tank_urgent()) or (ctx.get_ally_critical and ctx.get_ally_critical())
      return ally ~= nil
    end,

    execute = function(ctx)
      local ally = (ctx.get_tank_urgent and ctx.get_tank_urgent()) or (ctx.get_ally_critical and ctx.get_ally_critical())
      if ally and ctx.cast_spell_on then return ctx.cast_spell_on(116849, ally) end
      return false
    end,
  })
end


