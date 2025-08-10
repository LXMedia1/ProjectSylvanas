-- Earth Shock (ID: 8042)
-- Elemental spender
return function(engine)
  engine:register_spell({
    id = 8042,
    name = "Earth Shock",
    priority = 90,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(8042) then return false end
      if ctx.is_spec and not ctx.is_spec('Elemental') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'elemental') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx)
      -- Prefer to cast when Maelstrom high if API available; fallback always true
      if ctx.resource and ctx.resource('maelstrom') then
        return ctx.resource('maelstrom') >= 60
      end
      return true
    end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(8042, ctx.target) end
      return false
    end,
  })
end


