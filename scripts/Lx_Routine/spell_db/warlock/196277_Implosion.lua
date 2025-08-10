-- Implosion (ID: 196277)
-- Demonology AoE burst with imps
return function(engine)
  engine:register_spell({
    id = 196277,
    name = "Implosion",
    priority = 95,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(196277) then return false end
      if ctx.is_spec and not ctx.is_spec('Demonology') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'demonology') and not ctx.is_spec then return false end
      local n = ctx.enemies_close and ctx.enemies_close(10) or 0
      return n >= 3
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(196277) end
      return false
    end,
  })
end


