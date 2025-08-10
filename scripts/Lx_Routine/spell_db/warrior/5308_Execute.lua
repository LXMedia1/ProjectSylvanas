-- Execute (ID: 5308)
-- Finisher when target is low
return function(engine)
  engine:register_spell({
    id = 5308,
    name = "Execute",
    priority = 99,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.target.is_dead or not ctx.target.is_enemy then return false end
      if ctx.can_cast and not ctx.can_cast(5308) then return false end
      local hp = ctx.target.health_pct or 100
      local thr = (ctx.execute_threshold and ctx.execute_threshold(5308)) or 20
      return hp <= thr
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(5308, ctx.target) end
      return false
    end,
  })
end


