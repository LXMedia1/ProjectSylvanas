-- Vampiric Touch (ID: 34914)
-- Shadow DoT; hard cast. Refresh near expiration.
return function(engine)
  engine:register_spell({
    id = 34914,
    name = "Vampiric Touch",
    priority = 96,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.target.is_dead or not ctx.target.is_enemy then return false end
      if ctx.requires_los and not ctx.requires_los(34914, ctx.target) then return false end
      if ctx.is_in_range and not ctx.is_in_range(34914, ctx.target) then return false end
      if ctx.can_cast and not ctx.can_cast(34914) then return false end
      if ctx.player and ctx.player.is_moving then
        if ctx.can_cast_while_moving and ctx.can_cast_while_moving(34914) then else return false end
      end
      return true
    end,

    should_use = function(ctx)
      if ctx.aura_remaining then
        local remain = ctx.aura_remaining(ctx.target, 34914)
        return (not remain) or remain <= 3.0
      end
      if ctx.has_debuff then return not ctx.has_debuff(ctx.target, 34914) end
      return true
    end,

    execute = function(ctx)
      if ctx.cast_spell_on and ctx.target then
        return ctx.cast_spell_on(34914, ctx.target)
      elseif ctx.cast_spell then
        return ctx.cast_spell(34914)
      end
      return false
    end,
  })
end


