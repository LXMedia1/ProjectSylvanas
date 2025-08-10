-- Aspect of the Cheetah (ID: 186257)
-- Mobility; use to quickly reposition for pull/engage or escape
return function(engine)
  engine:register_spell({
    id = 186257,
    name = "Aspect of the Cheetah",
    priority = 70,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(186257) then return false end
      return true
    end,

    should_use = function(ctx)
      if ctx.is_in_ground_danger and ctx.is_in_ground_danger() then return true end
      local d = (ctx.target and ctx.distance_to and ctx.distance_to(ctx.target)) or nil
      return d and d > 25 and d < 60
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(186257) end
      return false
    end,
  })
end


