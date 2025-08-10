-- Whirlwind (ID: 1680)
-- AoE spender, multiple targets
return function(engine)
  engine:register_spell({
    id = 1680,
    name = "Whirlwind",
    priority = 70,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(1680) then return false end
      local n = ctx.enemies_close and ctx.enemies_close(8) or 0
      return n >= 3
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(1680) end
      return false
    end,
  })
end


