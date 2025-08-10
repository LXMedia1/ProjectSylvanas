-- Lava Burst (ID: 51505)
-- Elemental nuke; instant if Flame Shock on target
return function(engine)
  engine:register_spell({
    id = 51505,
    name = "Lava Burst",
    priority = 98,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(51505) then return false end
      if ctx.is_spec and not ctx.is_spec('Elemental') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'elemental') and not ctx.is_spec then return false end
      if ctx.player and ctx.player.is_moving then
        if ctx.can_cast_while_moving and ctx.can_cast_while_moving(51505) then else return false end
      end
      return true
    end,

    should_use = function(ctx)
      if ctx.has_debuff and ctx.has_debuff(ctx.target, 188389) then return true end
      return true
    end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(51505, ctx.target) end
      return false
    end,
  })
end


