-- Renew (ID: 139)
-- HoT maintenance on tank or injured allies.
return function(engine)
  engine:register_spell({
    id = 139,
    name = "Renew",
    priority = 87,

    is_usable = function(ctx)
      if not ctx or (ctx.can_cast and not ctx.can_cast(139)) then return false end
      local target = (ctx.get_tank and ctx.get_tank()) or (ctx.get_ally and ctx.get_ally()) or nil
      if not target then return false end
      if ctx.has_buff and ctx.has_buff(target, 139) then return false end
      return true
    end,

    should_use = function(ctx)
      local target = (ctx.get_tank and ctx.get_tank()) or (ctx.get_ally and ctx.get_ally()) or nil
      if not target then return false end
      local hp = target.health_pct or 100
      return hp < 90
    end,

    execute = function(ctx)
      local target = (ctx.get_tank and ctx.get_tank()) or (ctx.get_ally and ctx.get_ally()) or nil
      if target and ctx.cast_spell_on then
        return ctx.cast_spell_on(139, target)
      end
      return false
    end,
  })
end


