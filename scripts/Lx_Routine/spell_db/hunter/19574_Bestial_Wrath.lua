-- Bestial Wrath (ID: 19574)
-- BM major cooldown
return function(engine)
  engine:register_spell({
    id = 19574,
    name = "Bestial Wrath",
    priority = 100,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(19574) then return false end
      if ctx.is_spec and not ctx.is_spec('Beast Mastery') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'beast mastery') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx)
      if ctx.is_burst_window and ctx.is_burst_window() then return true end
      local n = ctx.enemies_close and ctx.enemies_close(10) or 0
      return n >= 3
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(19574) end
      return false
    end,
  })
end


