-- Healing Tide Totem (ID: 108280)
-- Raid healing cooldown
return function(engine)
  engine:register_spell({
    id = 108280,
    name = "Healing Tide Totem",
    priority = 180,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(108280) then return false end
      if ctx.is_spec and not ctx.is_spec('Restoration') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'restoration') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx)
      local injured = ctx.count_allies_below and ctx.count_allies_below(60) or 0
      return injured >= 5
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(108280) end
      return false
    end,
  })
end


