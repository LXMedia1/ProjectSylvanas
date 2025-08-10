-- Wake of Ashes (ID: 255937)
-- Ret AoE cone + generator
return function(engine)
  engine:register_spell({
    id = 255937,
    name = "Wake of Ashes",
    priority = 96,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(255937) then return false end
      return true
    end,

    should_use = function(ctx)
      local n = ctx.enemies_close and ctx.enemies_close(10) or 0
      return n >= 2
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(255937) end
      return false
    end,
  })
end


