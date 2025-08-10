-- Demoralizing Shout (ID: 1160)
-- Protection damage reduction on enemies; use on packs
return function(engine)
  engine:register_spell({
    id = 1160,
    name = "Demoralizing Shout",
    priority = 93,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(1160) then return false end
      local n = ctx.enemies_close and ctx.enemies_close(10) or 0
      return n >= 3
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(1160) end
      return false
    end,
  })
end


