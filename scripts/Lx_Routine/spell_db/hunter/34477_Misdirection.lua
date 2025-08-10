-- Misdirection (ID: 34477)
-- Transfer threat to tank or focus
return function(engine)
  engine:register_spell({
    id = 34477,
    name = "Misdirection",
    priority = 80,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(34477) then return false end
      local tank = (ctx.get_tank and ctx.get_tank()) or (ctx.get_focus and ctx.get_focus())
      return tank ~= nil
    end,

    should_use = function(ctx)
      return ctx.in_combat and ctx.in_combat()
    end,

    execute = function(ctx)
      local tank = (ctx.get_tank and ctx.get_tank()) or (ctx.get_focus and ctx.get_focus())
      if tank and ctx.cast_spell_on then return ctx.cast_spell_on(34477, tank) end
      return false
    end,
  })
end


