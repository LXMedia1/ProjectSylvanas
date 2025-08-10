-- Power Word: Barrier (ID: 62618)
-- Disc raid CD; use when many allies are low and stacked
return function(engine)
  engine:register_spell({
    id = 62618,
    name = "Power Word: Barrier",
    priority = 104,

    is_usable = function(ctx)
      if not ctx then return false end
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Power Word: Barrier") or 62618)) or 62618
      if ctx.can_cast and not ctx.can_cast(sid) then return false end
      return (ctx.count_allies_below and ctx.count_allies_below(50) or 0) >= 4
    end,

    should_use = function(ctx)
      if ctx.allies_stacked and not ctx.allies_stacked(8, 4) then return false end
      return true
    end,

    execute = function(ctx)
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Power Word: Barrier") or 62618)) or 62618
      if ctx.cast_spell then return ctx.cast_spell(sid) end
      return false
    end,
  })
end


