-- Holy Word: Sanctify (ID: 88684)
-- Big AoE heal around target location/ally cluster
return function(engine)
  engine:register_spell({
    id = 88684,
    name = "Holy Word: Sanctify",
    priority = 101,

    is_usable = function(ctx)
      if not ctx then return false end
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Holy Word: Sanctify") or 88684)) or 88684
      if ctx.can_cast and not ctx.can_cast(sid) then return false end
      return (ctx.count_allies_below and ctx.count_allies_below(70) or 0) >= 3
    end,

    should_use = function(ctx)
      return true
    end,

    execute = function(ctx)
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Holy Word: Sanctify") or 88684)) or 88684
      if ctx.cast_spell then return ctx.cast_spell(sid) end
      return false
    end,
  })
end


