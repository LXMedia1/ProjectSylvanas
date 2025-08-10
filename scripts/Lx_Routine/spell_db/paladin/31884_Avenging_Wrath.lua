-- Avenging Wrath (ID: 31884)
-- Major damage/healing cooldown
return function(engine)
  engine:register_spell({
    id = 31884,
    name = "Avenging Wrath",
    priority = 100,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(31884) then return false end
      return true
    end,

    should_use = function(ctx)
      if ctx.is_burst_window and ctx.is_burst_window() then return true end
      local n = ctx.enemies_close and ctx.enemies_close(10) or 0
      return n >= 3
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(31884) end
      return false
    end,
  })
end


