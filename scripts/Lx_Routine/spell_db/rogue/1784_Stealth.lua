-- Stealth (ID: 1784)
-- Enter stealth out of combat for openers
return function(engine)
  engine:register_spell({
    id = 1784,
    name = "Stealth",
    priority = 40,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.in_combat and ctx.in_combat() then return false end
      if ctx.can_cast and not ctx.can_cast(1784) then return false end
      local me = ctx.get_player and ctx.get_player() or nil
      if me and ctx.has_buff and ctx.has_buff(me, 1784) then return false end
      return true
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(1784) end
      return false
    end,
  })
end


