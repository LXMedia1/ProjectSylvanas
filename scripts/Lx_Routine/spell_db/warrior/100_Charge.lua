-- Charge (ID: 100)
-- Gap closer; use to engage out-of-range target
return function(engine)
  engine:register_spell({
    id = 100,
    name = "Charge",
    priority = 95,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.target.is_dead or not ctx.target.is_enemy then return false end
      if ctx.can_cast and not ctx.can_cast(100) then return false end
      -- Use when not in melee
      local d = ctx.distance_to and ctx.distance_to(ctx.target)
      return d and d > 8 and d < 25
    end,

    should_use = function(ctx)
      return true
    end,

    execute = function(ctx)
      if ctx.cast_spell_on and ctx.target then
        return ctx.cast_spell_on(100, ctx.target)
      elseif ctx.cast_spell then
        return ctx.cast_spell(100)
      end
      return false
    end,
  })
end


