-- Recklessness (ID: 1719)
-- Fury major cooldown
return function(engine)
  engine:register_spell({
    id = 1719,
    name = "Recklessness",
    priority = 105,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(1719) then return false end
      if ctx.is_spec and not ctx.is_spec('Fury') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'fury') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx)
      return ctx.is_burst_window and ctx.is_burst_window()
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(1719) end
      return false
    end,
  })
end


