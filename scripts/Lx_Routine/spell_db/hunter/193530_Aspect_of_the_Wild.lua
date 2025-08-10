-- Aspect of the Wild (ID: 193530)
-- BM cooldown
return function(engine)
  engine:register_spell({
    id = 193530,
    name = "Aspect of the Wild",
    priority = 99,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(193530) then return false end
      if ctx.is_spec and not ctx.is_spec('Beast Mastery') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'beast mastery') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx)
      return ctx.is_burst_window and ctx.is_burst_window()
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(193530) end
      return false
    end,
  })
end


