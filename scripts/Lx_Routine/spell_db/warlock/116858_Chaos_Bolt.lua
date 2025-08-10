-- Chaos Bolt (ID: 116858)
-- Destruction spender
return function(engine)
  engine:register_spell({
    id = 116858,
    name = "Chaos Bolt",
    priority = 95,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(116858) then return false end
      if ctx.is_spec and not ctx.is_spec('Destruction') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'destruction') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(116858, ctx.target) end
      return false
    end,
  })
end


