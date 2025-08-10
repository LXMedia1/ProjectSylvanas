-- Shadow Word: Death (ID: 32379)
-- Execute; prefer when target low HP. Beware backlash if not lethal.
return function(engine)
  engine:register_spell({
    id = 32379,
    name = "Shadow Word: Death",
    priority = 99,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.target.is_dead or not ctx.target.is_enemy then return false end
      if ctx.requires_los and not ctx.requires_los(32379, ctx.target) then return false end
      if ctx.is_in_range and not ctx.is_in_range(32379, ctx.target) then return false end
      if ctx.can_cast and not ctx.can_cast(32379) then return false end
      return true
    end,

    should_use = function(ctx)
      local hp = ctx.target and (ctx.target.health_pct or 100) or 100
      local threshold = 20
      if ctx.execute_threshold then threshold = ctx.execute_threshold(32379) or threshold end
      return hp <= threshold
    end,

    execute = function(ctx)
      if ctx.cast_spell_on and ctx.target then
        return ctx.cast_spell_on(32379, ctx.target)
      elseif ctx.cast_spell then
        return ctx.cast_spell(32379)
      end
      return false
    end,
  })
end


