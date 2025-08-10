-- Death and Decay (ID: 43265)
-- Ground AoE; Blood/Unholy AoE
return function(engine)
  engine:register_spell({
    id = 43265,
    name = "Death and Decay",
    priority = 80,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(43265) then return false end
      local n = ctx.enemies_close and ctx.enemies_close(8) or 0
      return n >= 2
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(43265) end
      return false
    end,
  })
end


