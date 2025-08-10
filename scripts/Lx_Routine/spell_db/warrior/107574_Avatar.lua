-- Avatar (ID: 107574)
-- Arms/Fury cooldown
return function(engine)
  engine:register_spell({
    id = 107574,
    name = "Avatar",
    priority = 100,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(107574) then return false end
      return true
    end,

    should_use = function(ctx)
      return ctx.is_burst_window and ctx.is_burst_window()
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(107574) end
      return false
    end,
  })
end


