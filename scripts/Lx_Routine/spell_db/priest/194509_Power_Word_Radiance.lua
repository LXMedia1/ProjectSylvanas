-- Power Word: Radiance (ID: 194509)
-- Discipline AoE heal + Atonement application.
return function(engine)
  engine:register_spell({
    id = 194509,
    name = "Power Word: Radiance",
    priority = 89,

    is_usable = function(ctx)
      if not ctx or (ctx.can_cast and not ctx.can_cast(194509)) then return false end
      return true
    end,

    should_use = function(ctx)
      -- Use when multiple allies below 80% or many lacking Atonement if helper exists
      local injured = ctx.count_allies_below and ctx.count_allies_below(80) or 0
      if injured >= 3 then return true end
      if ctx.count_without_atonement then
        local lacking = ctx.count_without_atonement()
        if lacking and lacking >= 3 then return true end
      end
      return false
    end,

    execute = function(ctx)
      if ctx.cast_spell then
        return ctx.cast_spell(194509)
      end
      return false
    end,
  })
end


