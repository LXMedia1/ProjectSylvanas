-- Pyroblast (ID: 11366)
-- Fire big nuke; prefer with Hot Streak
return function(engine)
  engine:register_spell({
    id = 11366,
    name = "Pyroblast",
    priority = 97,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(11366) then return false end
      if ctx.is_spec and not ctx.is_spec('Fire') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'fire') and not ctx.is_spec then return false end
      if ctx.player and ctx.player.is_moving then
        if ctx.can_cast_while_moving and ctx.can_cast_while_moving(11366) then else return false end
      end
      return true
    end,

    should_use = function(ctx)
      local me = ctx.get_player and ctx.get_player() or nil
      if me and ctx.has_buff and (ctx.has_buff(me, 48108) or ctx.has_buff(me, 48107)) then return true end
      return false
    end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(11366, ctx.target) end
      return false
    end,
  })
end



