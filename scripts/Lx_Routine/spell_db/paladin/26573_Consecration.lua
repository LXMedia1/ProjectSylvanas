-- Consecration (ID: 26573)
-- Ground AoE; maintain for Prot/Holy area healing/damage, Ret situational
return function(engine)
  engine:register_spell({
    id = 26573,
    name = "Consecration",
    priority = 70,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(26573) then return false end
      return true
    end,

    should_use = function(ctx)
      local enemies = ctx.enemies_close and ctx.enemies_close(8) or 0
      return enemies >= 2
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(26573) end
      return false
    end,
  })
end


