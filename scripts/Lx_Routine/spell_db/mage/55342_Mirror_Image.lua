-- Mirror Image (ID: 55342)
-- Defensive/offensive utility
return function(engine)
  engine:register_spell({
    id = 55342,
    name = "Mirror Image",
    priority = 90,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(55342) then return false end
      return true
    end,

    should_use = function(ctx)
      return ctx.is_burst_window and ctx.is_burst_window()
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(55342) end
      return false
    end,
  })
end


