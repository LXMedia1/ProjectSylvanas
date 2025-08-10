-- Phoenix Flames (ID: 257541)
-- Fire instant cleave/nuke; strong during Combustion
return function(engine)
  engine:register_spell({
    id = 257541,
    name = "Phoenix Flames",
    priority = 92,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(257541) then return false end
      if ctx.is_spec and not ctx.is_spec('Fire') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'fire') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx)
      local me = ctx.get_player and ctx.get_player() or nil
      if me and ctx.has_buff and ctx.has_buff(me, 190319) then return true end
      local n = ctx.enemies_close and ctx.enemies_close(8) or 0
      return n >= 2
    end,

    execute = function(ctx)
      if ctx.cast_spell_on and ctx.target then return ctx.cast_spell_on(257541, ctx.target) end
      return false
    end,
  })
end


