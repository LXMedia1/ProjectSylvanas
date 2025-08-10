-- Shadow Word: Pain (ID: 589)
-- Apply/refresh DoT on enemy targets; instant and usable while moving
return function(engine)
  engine:register_spell({
    id = 589,
    name = "Shadow Word: Pain",
    priority = 90,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.target.is_dead then return false end
      if not ctx.target.is_enemy then return false end
      if ctx.requires_los and not ctx.requires_los(589, ctx.target) then return false end
      if ctx.is_in_range and not ctx.is_in_range(589, ctx.target) then return false end
      if ctx.can_cast and not ctx.can_cast(589) then return false end
      return true
    end,

    should_use = function(ctx)
      -- Use if missing or about to expire (fallback to missing if no API available)
      if ctx.aura_remaining then
        local remain = ctx.aura_remaining(ctx.target, 589)
        if not remain or remain <= 3.0 then return true end
        return false
      end
      if ctx.has_debuff then
        return not ctx.has_debuff(ctx.target, 589)
      end
      return true
    end,

    execute = function(ctx)
      if ctx.cast_spell_on and ctx.target then
        return ctx.cast_spell_on(589, ctx.target)
      elseif ctx.cast_spell then
        return ctx.cast_spell(589)
      end
      return false
    end,
  })
end


