-- Shadowfiend (ID: 34433)
-- Major cooldown; summon pet to attack. Use in combat vs. important targets.
return function(engine)
  engine:register_spell({
    id = 34433,
    name = "Shadowfiend",
    priority = 85,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(34433) then return false end
      if not ctx.target or not ctx.target.is_enemy or ctx.target.is_dead then return false end
      if ctx.is_in_range and not ctx.is_in_range(34433, ctx.target) then return false end
      return true
    end,

    should_use = function(ctx)
      -- Prefer when in sustained combat (avoid trivial mobs if a helper exists)
      if ctx.is_boss_or_elite and ctx.target then
        return ctx.is_boss_or_elite(ctx.target)
      end
      return true
    end,

    execute = function(ctx)
      if ctx.cast_spell then
        return ctx.cast_spell(34433)
      end
      return false
    end,
  })
end


