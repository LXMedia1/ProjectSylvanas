-- Immolation Aura (ID: 258920)
-- Havoc/Vengeance AoE
return function(engine)
  engine:register_spell({
    id = 258920,
    name = "Immolation Aura",
    priority = 80,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(258920) then return false end
      local n = ctx.enemies_close and ctx.enemies_close(8) or 0
      return n >= 2
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(258920) end
      return false
    end,
  })
end


