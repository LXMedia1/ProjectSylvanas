-- Innervate (ID: 29166)
-- Resto/Balance utility: mana-free casting on target healer/self
return function(engine)
  engine:register_spell({
    id = 29166,
    name = "Innervate",
    priority = 130,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(29166) then return false end
      return true
    end,

    should_use = function(ctx)
      -- Prefer when many allies are low (healing intensive)
      local injured = ctx.count_allies_below and ctx.count_allies_below(85) or 0
      return injured >= 4
    end,

    execute = function(ctx)
      local target = (ctx.get_healer and ctx.get_healer()) or (ctx.get_player and ctx.get_player())
      if target and ctx.cast_spell_on then return ctx.cast_spell_on(29166, target) end
      return false
    end,
  })
end


