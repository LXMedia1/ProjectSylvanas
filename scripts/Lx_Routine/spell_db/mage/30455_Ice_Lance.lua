-- Ice Lance (ID: 30455)
-- Frost instant; prioritize when the target is frozen or Fingers of Frost is active
return function(engine)
  engine:register_spell({
    id = 30455,
    name = "Ice Lance",
    priority = 85,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.target.is_dead or not ctx.target.is_enemy then return false end
      if ctx.can_cast and not ctx.can_cast(30455) then return false end
      -- Spec gate: Frost
      if ctx.is_spec and not ctx.is_spec('Frost') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'frost') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx)
      local me = ctx.get_player and ctx.get_player() or nil
      if ctx.has_buff and me then
        -- Fingers of Frost typical IDs (not guaranteed): 44544, 112965
        if ctx.has_buff(me, 44544) or ctx.has_buff(me, 112965) then return true end
      end
      -- If target frozen (nova/root), prefer lance
      if ctx.has_debuff and ctx.has_debuff(ctx.target, 122) then return true end
      return false
    end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(30455, ctx.target) end
      return false
    end,
  })
end


