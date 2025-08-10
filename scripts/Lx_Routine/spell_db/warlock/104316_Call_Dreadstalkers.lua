-- Call Dreadstalkers (ID: 104316)
-- Demonology summon
return function(engine)
  engine:register_spell({
    id = 104316,
    name = "Call Dreadstalkers",
    priority = 92,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(104316) then return false end
      if ctx.is_spec and not ctx.is_spec('Demonology') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'demonology') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(104316, ctx.target) end
      return false
    end,
  })
end


