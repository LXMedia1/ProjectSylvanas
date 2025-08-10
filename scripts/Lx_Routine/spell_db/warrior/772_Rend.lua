-- Rend (ID: 772)
-- Bleed maintenance (Arms)
return function(engine)
  engine:register_spell({
    id = 772,
    name = "Rend",
    priority = 85,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.target.is_dead or not ctx.target.is_enemy then return false end
      if ctx.can_cast and not ctx.can_cast(772) then return false end
      local d = ctx.distance_to and ctx.distance_to(ctx.target)
      if not (d and d <= 5) then return false end
      return true
    end,

    should_use = function(ctx)
      if ctx.aura_remaining then
        local remain = ctx.aura_remaining(ctx.target, 772)
        return (not remain) or remain <= 3.0
      end
      if ctx.has_debuff then return not ctx.has_debuff(ctx.target, 772) end
      return true
    end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(772, ctx.target) end
      return false
    end,
  })
end


