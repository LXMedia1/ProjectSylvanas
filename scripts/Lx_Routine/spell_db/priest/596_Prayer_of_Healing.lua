-- Prayer of Healing (ID: 596)
-- Group heal; use when multiple allies are moderately injured
return function(engine)
  engine:register_spell({
    id = 596,
    name = "Prayer of Healing",
    priority = 90,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(596) then return false end
      return (ctx.count_allies_below and ctx.count_allies_below(80) or 0) >= 3
    end,

    should_use = function(ctx)
      return true
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(596) end
      return false
    end,
  })
end


