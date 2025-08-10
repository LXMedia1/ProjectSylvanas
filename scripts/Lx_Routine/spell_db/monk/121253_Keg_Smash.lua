-- Keg Smash (ID: 121253)
-- Brewmaster core AoE builder
return function(engine)
  engine:register_spell({
    id = 121253,
    name = "Keg Smash",
    priority = 95,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(121253) then return false end
      if ctx.is_spec and not ctx.is_spec('Brewmaster') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'brewmaster') and not ctx.is_spec then return false end
      local n = ctx.enemies_close and ctx.enemies_close(8) or 0
      return n >= 1
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(121253) end
      return false
    end,
  })
end


