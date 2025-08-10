-- Vampiric Embrace (ID: 15286)
-- Shadow raid healing cooldown; use during burst or high raid damage
return function(engine)
  engine:register_spell({
    id = 15286,
    name = "Vampiric Embrace",
    priority = 83,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(15286) then return false end
      return true
    end,

    should_use = function(ctx)
      if ctx.is_burst_window and ctx.is_burst_window() then return true end
      return (ctx.count_allies_below and ctx.count_allies_below(70) or 0) >= 3
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(15286) end
      return false
    end,
  })
end


