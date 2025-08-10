-- Capacitor Totem (ID: 192058)
-- AoE stun totem
return function(engine)
  engine:register_spell({
    id = 192058,
    name = "Capacitor Totem",
    priority = 115,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(192058) then return false end
      local n = ctx.enemies_close and ctx.enemies_close(8) or 0
      return n >= 3
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(192058) end
      return false
    end,
  })
end


