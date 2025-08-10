-- Roll the Bones (ID: 315508)
-- Outlaw finisher/buff roll
return function(engine)
  engine:register_spell({
    id = 315508,
    name = "Roll the Bones",
    priority = 85,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(315508) then return false end
      if ctx.is_spec and not ctx.is_spec('Outlaw') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'outlaw') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx)
      return true
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(315508) end
      return false
    end,
  })
end


