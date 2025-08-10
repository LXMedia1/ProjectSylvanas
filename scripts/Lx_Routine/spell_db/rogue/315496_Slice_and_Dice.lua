-- Slice and Dice (ID: 315496)
-- Attack speed buff
return function(engine)
  engine:register_spell({
    id = 315496,
    name = "Slice and Dice",
    priority = 70,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(315496) then return false end
      return true
    end,

    should_use = function(ctx)
      local me = ctx.get_player and ctx.get_player() or nil
      if not me then return false end
      if ctx.has_buff and ctx.has_buff(me, 315496) then return false end
      if ctx.combo_points and ctx.combo_points() then return ctx.combo_points() >= 5 end
      return false
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(315496) end
      return false
    end,
  })
end


