-- Anti-Magic Zone (ID: 51052)
-- Group magic damage reduction
return function(engine)
  engine:register_spell({
    id = 51052,
    name = "Anti-Magic Zone",
    priority = 180,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(51052) then return false end
      return true
    end,

    should_use = function(ctx)
      local injured = ctx.count_allies_below and ctx.count_allies_below(60) or 0
      return injured >= 3
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(51052) end
      return false
    end,
  })
end



