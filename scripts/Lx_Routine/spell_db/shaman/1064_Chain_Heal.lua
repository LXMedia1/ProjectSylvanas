-- Chain Heal (ID: 1064)
-- Resto multi-target heal
return function(engine)
  engine:register_spell({
    id = 1064,
    name = "Chain Heal",
    priority = 110,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(1064) then return false end
      if ctx.is_spec and not ctx.is_spec('Restoration') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'restoration') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx)
      local injured = ctx.count_allies_below and ctx.count_allies_below(80) or 0
      return injured >= 3
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(1064) end
      return false
    end,
  })
end


