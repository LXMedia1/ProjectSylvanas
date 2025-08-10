-- Adrenaline Rush (ID: 13750)
-- Outlaw cooldown
return function(engine)
  engine:register_spell({
    id = 13750,
    name = "Adrenaline Rush",
    priority = 100,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(13750) then return false end
      if ctx.is_spec and not ctx.is_spec('Outlaw') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'outlaw') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx)
      return ctx.is_burst_window and ctx.is_burst_window()
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(13750) end
      return false
    end,
  })
end


