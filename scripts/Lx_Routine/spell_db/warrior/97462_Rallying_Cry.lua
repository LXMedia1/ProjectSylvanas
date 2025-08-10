-- Rallying Cry (ID: 97462)
-- Group defensive
return function(engine)
  engine:register_spell({
    id = 97462,
    name = "Rallying Cry",
    priority = 180,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(97462) then return false end
      return true
    end,

    should_use = function(ctx)
      local injured = ctx.count_allies_below and ctx.count_allies_below(40) or 0
      return injured >= 3
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(97462) end
      return false
    end,
  })
end


