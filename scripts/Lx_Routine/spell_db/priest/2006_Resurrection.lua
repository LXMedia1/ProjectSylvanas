-- Resurrection (ID: 2006)
-- Out-of-combat rez for Priests
return function(engine)
  engine:register_spell({
    id = 2006,
    name = "Resurrection",
    priority = 50,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.in_combat and ctx.in_combat() then return false end
      if ctx.can_cast and not ctx.can_cast(2006) then return false end
      if ctx.get_ally_to_res then return ctx.get_ally_to_res() ~= nil end
      return false
    end,

    should_use = function(ctx)
      return true
    end,

    execute = function(ctx)
      local ally = ctx.get_ally_to_res and ctx.get_ally_to_res()
      if ally and ctx.cast_spell_on then
        return ctx.cast_spell_on(2006, ally)
      end
      return false
    end,
  })
end


