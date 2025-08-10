-- Sprint (ID: 2983)
-- Movement speed boost
return function(engine)
  engine:register_spell({
    id = 2983,
    name = "Sprint",
    priority = 60,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(2983) then return false end
      return true
    end,

    should_use = function(ctx)
      return (ctx.is_in_ground_danger and ctx.is_in_ground_danger()) or ((ctx.target and ctx.distance_to) and (ctx.distance_to(ctx.target) > 15))
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(2983) end
      return false
    end,
  })
end


