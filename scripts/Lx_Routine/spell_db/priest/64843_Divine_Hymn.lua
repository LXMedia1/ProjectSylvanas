-- Divine Hymn (ID: 64843)
-- Major raid healing cooldown
return function(engine)
  engine:register_spell({
    id = 64843,
    name = "Divine Hymn",
    priority = 106,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(64843) then return false end
      return (ctx.count_allies_below and ctx.count_allies_below(60) or 0) >= 5
    end,

    should_use = function(ctx)
      return true
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(64843) end
      return false
    end,
  })
end


