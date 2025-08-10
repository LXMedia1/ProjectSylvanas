-- Holy Fire (ID: 14914)
-- Strong opener: direct damage + DoT; prefer on pull or when DoT missing/expiring
return function(engine)
  engine:register_spell({
    id = 14914,
    name = "Holy Fire",
    priority = 95,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.target.is_dead then return false end
      if not ctx.target.is_enemy then return false end
      if ctx.requires_los and not ctx.requires_los(14914, ctx.target) then return false end
      if ctx.is_in_range and not ctx.is_in_range(14914, ctx.target) then return false end
      if ctx.can_cast and not ctx.can_cast(14914) then return false end
      if ctx.player and ctx.player.is_moving then
        if ctx.can_cast_while_moving and ctx.can_cast_while_moving(14914) then
          -- allowed while moving (e.g., special buff)
        else
          return false
        end
      end
      return true
    end,

    should_use = function(ctx)
      -- Prefer when its DoT component is missing or low
      if ctx.aura_remaining then
        local remain = ctx.aura_remaining(ctx.target, 14914)
        if not remain or remain <= 2.0 then return true end
        return false
      end
      if ctx.has_debuff then
        return not ctx.has_debuff(ctx.target, 14914)
      end
      return true
    end,

    execute = function(ctx)
      if ctx.cast_spell_on and ctx.target then
        return ctx.cast_spell_on(14914, ctx.target)
      elseif ctx.cast_spell then
        return ctx.cast_spell(14914)
      end
      return false
    end,
  })
end


