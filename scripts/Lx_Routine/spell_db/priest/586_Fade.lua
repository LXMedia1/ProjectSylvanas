-- Fade (ID: 586)
-- Threat drop; use when over-aggro detected
return function(engine)
  engine:register_spell({
    id = 586,
    name = "Fade",
    priority = 62,

    is_usable = function(ctx)
      if not ctx then return false end
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Fade") or 586)) or 586
      if ctx.can_cast and not ctx.can_cast(sid) then return false end
      if ctx.over_aggro and ctx.over_aggro() then return true end
      return false
    end,

    should_use = function(ctx)
      return true
    end,

    execute = function(ctx)
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Fade") or 586)) or 586
      if ctx.cast_spell then return ctx.cast_spell(sid) end
      return false
    end,
  })
end


