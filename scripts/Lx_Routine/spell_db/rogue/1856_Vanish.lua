-- Vanish (ID: 1856)
-- Re-enter stealth mid-combat for openers/escape
return function(engine)
  engine:register_spell({
    id = 1856,
    name = "Vanish",
    priority = 160,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(1856) then return false end
      return true
    end,

    should_use = function(ctx)
      local me = ctx.get_player and ctx.get_player() or nil
      if not me then return false end
      return (me.health_pct or 100) <= 30
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(1856) end
      return false
    end,
  })
end


