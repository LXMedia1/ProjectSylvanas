-- Pistol Shot (ID: 185763)
-- Outlaw ranged proc/slow
return function(engine)
  engine:register_spell({
    id = 185763,
    name = "Pistol Shot",
    priority = 60,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(185763) then return false end
      if ctx.is_spec and not ctx.is_spec('Outlaw') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'outlaw') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx)
      local me = ctx.get_player and ctx.get_player() or nil
      if me and ctx.has_buff then
        -- Opportunity proc (typical id 195627)
        if ctx.has_buff(me, 195627) then return true end
      end
      return false
    end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(185763, ctx.target) end
      return false
    end,
  })
end


