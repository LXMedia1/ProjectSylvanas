-- Shield Block (ID: 2565)
-- Protection defensive; use on heavy physical damage
return function(engine)
  engine:register_spell({
    id = 2565,
    name = "Shield Block",
    priority = 100,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(2565) then return false end
      return true
    end,

    should_use = function(ctx)
      local incoming = ctx.expected_damage_in and ctx.expected_damage_in(ctx.get_player(), 2.0) or 0
      return incoming and incoming > 0
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(2565) end
      return false
    end,
  })
end


