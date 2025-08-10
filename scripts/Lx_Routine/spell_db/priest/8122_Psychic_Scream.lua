-- Psychic Scream (ID: 8122)
-- AoE fear for control; avoid if it would break CC rules if context provides
return function(engine)
  engine:register_spell({
    id = 8122,
    name = "Psychic Scream",
    priority = 65,

    is_usable = function(ctx)
      if not ctx then return false end
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Psychic Scream") or 8122)) or 8122
      if ctx.can_cast and not ctx.can_cast(sid) then return false end
      local n = ctx.enemies_close and ctx.enemies_close(8) or 0
      return n >= 2
    end,

    should_use = function(ctx)
      if ctx.avoid_cc_break and not ctx.avoid_cc_break() then return false end
      return true
    end,

    execute = function(ctx)
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Psychic Scream") or 8122)) or 8122
      if ctx.cast_spell then return ctx.cast_spell(sid) end
      return false
    end,
  })
end


