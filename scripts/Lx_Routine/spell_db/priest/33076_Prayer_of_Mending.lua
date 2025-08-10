-- Prayer of Mending (ID: 33076)
-- Holy/Disc utility; pre-emptive bouncing heal. Use on tank or injured ally when charge missing.
return function(engine)
  engine:register_spell({
    id = 33076,
    name = "Prayer of Mending",
    priority = 80,

    is_usable = function(ctx)
      if not ctx or (ctx.can_cast and not ctx.can_cast(33076)) then return false end
      local target = (ctx.get_tank and ctx.get_tank()) or (ctx.get_ally and ctx.get_ally()) or nil
      if not target then return false end
      if ctx.has_buff and ctx.has_buff(target, 33076) then return false end
      return true
    end,

    should_use = function(ctx)
      local target = (ctx.get_tank and ctx.get_tank()) or (ctx.get_ally and ctx.get_ally()) or nil
      if not target then return false end
      local hp = target.health_pct or 100
      return hp < 95
    end,

    execute = function(ctx)
      local target = (ctx.get_tank and ctx.get_tank()) or (ctx.get_ally and ctx.get_ally()) or nil
      if target and ctx.cast_spell_on then
        return ctx.cast_spell_on(33076, target)
      end
      return false
    end,
  })
end


