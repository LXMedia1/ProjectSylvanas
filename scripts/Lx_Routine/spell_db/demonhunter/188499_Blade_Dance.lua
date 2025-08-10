-- Blade Dance (ID: 188499)
-- Havoc AoE spender
return function(engine)
  engine:register_spell({
    id = 188499,
    name = "Blade Dance",
    priority = 90,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(188499) then return false end
      local n = ctx.enemies_close and ctx.enemies_close(8) or 0
      return n >= 3
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(188499) end
      return false
    end,
  })
end


