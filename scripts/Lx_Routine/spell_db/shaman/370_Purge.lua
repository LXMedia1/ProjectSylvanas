-- Purge (ID: 370)
-- Offensive dispel
return function(engine)
  engine:register_spell({
    id = 370,
    name = "Purge",
    priority = 90,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(370) then return false end
      if ctx.enemy_has_dispellable and ctx.enemy_has_dispellable(ctx.target) then return true end
      return false
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(370, ctx.target) end
      return false
    end,
  })
end


