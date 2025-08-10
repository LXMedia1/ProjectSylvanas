-- Touch of the Magi (ID: 321507)
-- Arcane burst window
return function(engine)
  engine:register_spell({
    id = 321507,
    name = "Touch of the Magi",
    priority = 100,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(321507) then return false end
      if ctx.is_spec and not ctx.is_spec('Arcane') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'arcane') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx)
      if ctx.is_burst_window and ctx.is_burst_window() then return true end
      return false
    end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(321507, ctx.target) end
      return false
    end,
  })
end


