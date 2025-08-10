-- Blood Boil (ID: 50842)
-- Blood AoE generator
return function(engine)
  engine:register_spell({
    id = 50842,
    name = "Blood Boil",
    priority = 88,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(50842) then return false end
      if ctx.is_spec and not ctx.is_spec('Blood') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'blood') and not ctx.is_spec then return false end
      local n = ctx.enemies_close and ctx.enemies_close(8) or 0
      return n >= 2
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(50842) end
      return false
    end,
  })
end


