-- Drain Life (ID: 234153)
-- Self sustain channel
return function(engine)
  engine:register_spell({
    id = 234153,
    name = "Drain Life",
    priority = 100,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(234153) then return false end
      return true
    end,

    should_use = function(ctx)
      local me = ctx.get_player and ctx.get_player() or nil
      if not me then return false end
      return (me.health_pct or 100) <= 50
    end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(234153, ctx.target) end
      return false
    end,
  })
end


