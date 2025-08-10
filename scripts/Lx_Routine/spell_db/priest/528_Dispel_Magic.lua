-- Dispel Magic (ID: 528)
-- Offensive dispel: remove 1 beneficial magic effect from an enemy
return function(engine)
  engine:register_spell({
    id = 528,
    name = "Dispel Magic",
    priority = 70,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if not ctx.target.is_enemy or ctx.target.is_dead then return false end
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Dispel Magic") or 528)) or 528
      if ctx.can_cast and not ctx.can_cast(sid) then return false end
      if ctx.can_dispel_enemy and not ctx.can_dispel_enemy(ctx.target) then return false end
      return true
    end,

    should_use = function(ctx)
      if ctx.enemy_has_dispellable and ctx.enemy_has_dispellable(ctx.target) then return true end
      return false
    end,

    execute = function(ctx)
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Dispel Magic") or 528)) or 528
      if ctx.cast_spell_on and ctx.target then
        return ctx.cast_spell_on(sid, ctx.target)
      end
      return false
    end,
  })
end


