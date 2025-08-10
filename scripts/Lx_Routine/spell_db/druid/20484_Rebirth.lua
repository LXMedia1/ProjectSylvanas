-- Rebirth (ID: 20484)
-- Battle resurrection
return function(engine)
  engine:register_spell({
    id = 20484,
    name = "Rebirth",
    priority = 180,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.in_combat and not ctx.in_combat() then return false end
      if ctx.can_cast and not ctx.can_cast(20484) then return false end
      if not ctx.get_ally_to_res then return false end
      return ctx.get_ally_to_res() ~= nil
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      local ally = ctx.get_ally_to_res and ctx.get_ally_to_res()
      if ally and ctx.cast_spell_on then return ctx.cast_spell_on(20484, ally) end
      return false
    end,
  })
end


