-- Spiritbloom (ID: 367226)
-- Preservation empowered heal (baseline cast here)
return function(engine)
  engine:register_spell({
    id = 367226,
    name = "Spiritbloom",
    priority = 130,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(367226) then return false end
      if ctx.is_spec and not ctx.is_spec('Preservation') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'preservation') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx)
      local injured = ctx.count_allies_below and ctx.count_allies_below(70) or 0
      return injured >= 3
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(367226) end
      return false
    end,
  })
end


