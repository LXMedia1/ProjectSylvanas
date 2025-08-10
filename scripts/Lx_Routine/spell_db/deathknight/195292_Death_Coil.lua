-- Death Coil (ID: 195292)
-- Unholy/Blood runic spender (use 47541 in some builds; resolve by name if needed)
return function(engine)
  engine:register_spell({
    id = 195292,
    name = "Death Coil",
    priority = 85,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id('Death Coil') or 195292)) or 195292
      if ctx.can_cast and not ctx.can_cast(sid) then return false end
      return true
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id('Death Coil') or 195292)) or 195292
      if ctx.cast_spell_on then return ctx.cast_spell_on(sid, ctx.target) end
      return false
    end,
  })
end


