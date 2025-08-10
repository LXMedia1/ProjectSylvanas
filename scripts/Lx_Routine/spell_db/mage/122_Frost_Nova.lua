-- Frost Nova (ID: 122)
-- Root/stop for control
return function(engine)
  engine:register_spell({
    id = 122,
    name = "Frost Nova",
    priority = 80,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(122) then return false end
      local n = ctx.enemies_close and ctx.enemies_close(8) or 0
      return n >= 1
    end,

    should_use = function(ctx)
      return ctx.is_in_ground_danger and ctx.is_in_ground_danger()
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(122) end
      return false
    end,
  })
end


