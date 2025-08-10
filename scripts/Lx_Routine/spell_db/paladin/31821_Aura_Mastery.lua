-- Aura Mastery (ID: 31821)
-- Holy raid CD
return function(engine)
  engine:register_spell({
    id = 31821,
    name = "Aura Mastery",
    priority = 180,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(31821) then return false end
      return true
    end,

    should_use = function(ctx)
      local injured = ctx.count_allies_below and ctx.count_allies_below(60) or 0
      return injured >= 5
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(31821) end
      return false
    end,
  })
end


