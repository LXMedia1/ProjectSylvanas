-- Blink (ID: 1953) / Shimmer replacement handled via resolve_spell_id if needed
-- Mobility/escape; use to avoid ground danger or close distance when safe
return function(engine)
  engine:register_spell({
    id = 1953,
    name = "Blink",
    priority = 75,

    is_usable = function(ctx)
      if not ctx then return false end
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id('Blink') or 1953)) or 1953
      if ctx.can_cast and not ctx.can_cast(sid) then return false end
      return true
    end,

    should_use = function(ctx)
      if ctx.is_in_ground_danger and ctx.is_in_ground_danger() then return true end
      local d = (ctx.target and ctx.distance_to and ctx.distance_to(ctx.target)) or nil
      return d and d > 10 and d < 30
    end,

    execute = function(ctx)
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id('Blink') or 1953)) or 1953
      if ctx.cast_spell then return ctx.cast_spell(sid) end
      return false
    end,
  })
end


