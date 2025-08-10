-- Victory Rush (ID: 34428)
-- Heal on hit proc after killing blow; use on cooldown if proc active
return function(engine)
  engine:register_spell({
    id = 34428,
    name = "Victory Rush",
    priority = 96,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.target.is_dead or not ctx.target.is_enemy then return false end
      if ctx.can_cast and not ctx.can_cast(34428) then return false end
      local d = ctx.distance_to and ctx.distance_to(ctx.target)
      if not (d and d <= 5) then return false end
      -- Assume host exposes proc via buff
      local me = ctx.get_player and ctx.get_player()
      if ctx.has_buff and me then
        return ctx.has_buff(me, 32216) or ctx.has_buff(me, 118779) or true -- fallback permissive
      end
      return true
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(34428, ctx.target) end
      return false
    end,
  })
end


