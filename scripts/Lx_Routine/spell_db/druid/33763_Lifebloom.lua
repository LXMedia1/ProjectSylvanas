-- Lifebloom (ID: 33763)
-- Resto tank HoT
return function(engine)
  engine:register_spell({
    id = 33763,
    name = "Lifebloom",
    priority = 94,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(33763) then return false end
      if ctx.is_spec and not ctx.is_spec('Restoration') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'restoration') and not ctx.is_spec then return false end
      local tank = ctx.get_tank and ctx.get_tank()
      return tank ~= nil
    end,

    should_use = function(ctx)
      local tank = ctx.get_tank and ctx.get_tank()
      if not tank then return false end
      if ctx.has_buff and ctx.has_buff(tank, 33763) then return false end
      return true
    end,

    execute = function(ctx)
      local tank = ctx.get_tank and ctx.get_tank()
      if tank and ctx.cast_spell_on then return ctx.cast_spell_on(33763, tank) end
      return false
    end,
  })
end


