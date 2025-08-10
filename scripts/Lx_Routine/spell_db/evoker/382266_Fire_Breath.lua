-- Fire Breath (ID: 382266)
-- Devastation empowered cone; cast baseline without empowerment logic here
return function(engine)
  engine:register_spell({
    id = 382266,
    name = "Fire Breath",
    priority = 98,

    is_usable = function(ctx)
      if not ctx then return false end
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id('Fire Breath') or 382266)) or 382266
      if ctx.can_cast and not ctx.can_cast(sid) then return false end
      if ctx.is_spec and not ctx.is_spec('Devastation') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'devastation') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx)
      local n = ctx.enemies_close and ctx.enemies_close(10) or 0
      return n >= 2
    end,

    execute = function(ctx)
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id('Fire Breath') or 382266)) or 382266
      if ctx.cast_spell then return ctx.cast_spell(sid) end
      return false
    end,
  })
end


