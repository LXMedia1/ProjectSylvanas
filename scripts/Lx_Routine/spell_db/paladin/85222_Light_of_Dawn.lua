-- Light of Dawn (ID: 85222)
-- Holy cone AoE heal; use when multiple allies are low
return function(engine)
  engine:register_spell({
    id = 85222,
    name = "Light of Dawn",
    priority = 117,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(85222) then return false end
      if ctx.is_spec and not ctx.is_spec('Holy') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'holy') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx)
      local injured = ctx.count_allies_below and ctx.count_allies_below(80) or 0
      return injured >= 3
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(85222) end
      return false
    end,
  })
end


