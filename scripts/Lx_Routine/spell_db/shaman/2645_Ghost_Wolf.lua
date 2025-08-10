-- Ghost Wolf (ID: 2645)
-- Movement form; use out of combat to travel/move faster
return function(engine)
  engine:register_spell({
    id = 2645,
    name = "Ghost Wolf",
    priority = 30,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.in_combat and ctx.in_combat() then return false end
      if ctx.can_cast and not ctx.can_cast(2645) then return false end
      local me = ctx.get_player and ctx.get_player() or nil
      if me and ctx.has_buff and ctx.has_buff(me, 2645) then return false end
      return true
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(2645) end
      return false
    end,
  })
end


