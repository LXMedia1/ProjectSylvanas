-- Multi-Shot (ID: 257620)
-- Cleave trigger; applies cleave buffs for BM/MM
return function(engine)
  engine:register_spell({
    id = 257620,
    name = "Multi-Shot",
    priority = 65,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(257620) then return false end
      local n = ctx.enemies_close and ctx.enemies_close(10) or 0
      return n >= 2
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(257620) end
      return false
    end,
  })
end


