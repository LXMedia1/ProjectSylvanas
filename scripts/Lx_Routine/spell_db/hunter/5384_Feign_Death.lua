-- Feign Death (ID: 5384)
-- Threat drop/safety; use on lethal threat
return function(engine)
  engine:register_spell({
    id = 5384,
    name = "Feign Death",
    priority = 150,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(5384) then return false end
      return ctx.over_aggro and ctx.over_aggro()
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(5384) end
      return false
    end,
  })
end


