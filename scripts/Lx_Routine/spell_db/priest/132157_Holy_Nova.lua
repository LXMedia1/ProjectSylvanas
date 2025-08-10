-- Holy Nova (ID: 132157)
-- Short-range AoE heal/damage; use when many enemies and allies are in melee
return function(engine)
  engine:register_spell({
    id = 132157,
    name = "Holy Nova",
    priority = 50,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(132157) then return false end
      local enemies = ctx.enemies_close and ctx.enemies_close(12) or 0
      local allies = ctx.allies_close and ctx.allies_close(12) or 0
      return enemies >= 3 or allies >= 3
    end,

    should_use = function(ctx)
      return true
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(132157) end
      return false
    end,
  })
end


