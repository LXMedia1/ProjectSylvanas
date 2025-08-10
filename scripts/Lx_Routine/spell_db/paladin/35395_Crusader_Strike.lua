-- Crusader Strike (ID: 35395)
-- Melee builder for Ret/Prot
return function(engine)
  engine:register_spell({
    id = 35395,
    name = "Crusader Strike",
    priority = 60,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.target.is_dead or not ctx.target.is_enemy then return false end
      if ctx.can_cast and not ctx.can_cast(35395) then return false end
      local d = ctx.distance_to and ctx.distance_to(ctx.target)
      return d and d <= 5
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(35395, ctx.target) end
      return false
    end,
  })
end


