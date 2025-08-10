-- Metamorphosis (ID: 191427)
-- Havoc major cooldown
return function(engine)
  engine:register_spell({
    id = 191427,
    name = "Metamorphosis",
    priority = 110,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(191427) then return false end
      return true
    end,

    should_use = function(ctx)
      return ctx.is_burst_window and ctx.is_burst_window()
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(191427) end
      return false
    end,
  })
end


