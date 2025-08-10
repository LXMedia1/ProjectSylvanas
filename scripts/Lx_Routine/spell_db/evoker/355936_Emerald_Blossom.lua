-- Emerald Blossom (ID: 355936)
-- Preservation AoE heal
return function(engine)
  engine:register_spell({
    id = 355936,
    name = "Emerald Blossom",
    priority = 115,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(355936) then return false end
      if ctx.is_spec and not ctx.is_spec('Preservation') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'preservation') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx)
      local injured = ctx.count_allies_below and ctx.count_allies_below(85) or 0
      return injured >= 3
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(355936) end
      return false
    end,
  })
end


