-- Swiftmend (ID: 18562)
-- Resto instant burst heal
return function(engine)
  engine:register_spell({
    id = 18562,
    name = "Swiftmend",
    priority = 118,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(18562) then return false end
      if ctx.is_spec and not ctx.is_spec('Restoration') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'restoration') and not ctx.is_spec then return false end
      return (ctx.get_ally_urgent and ctx.get_ally_urgent()) ~= nil
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      local ally = ctx.get_ally_urgent and ctx.get_ally_urgent()
      if ally and ctx.cast_spell_on then return ctx.cast_spell_on(18562, ally) end
      return false
    end,
  })
end


