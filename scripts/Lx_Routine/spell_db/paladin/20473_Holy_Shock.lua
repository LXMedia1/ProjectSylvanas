-- Holy Shock (ID: 20473)
-- Holy instant heal/nuke; prioritize healing
return function(engine)
  engine:register_spell({
    id = 20473,
    name = "Holy Shock",
    priority = 119,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(20473) then return false end
      if ctx.is_spec and not ctx.is_spec('Holy') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'holy') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx)
      local ally = (ctx.get_ally_urgent and ctx.get_ally_urgent()) or (ctx.get_ally_lowest and ctx.get_ally_lowest())
      if ally and (ally.health_pct or 100) <= 75 then return true end
      -- fallback: damage if no urgent heals
      return ctx.target and ctx.target.is_enemy and not ctx.target.is_dead
    end,

    execute = function(ctx)
      local ally = (ctx.get_ally_urgent and ctx.get_ally_urgent()) or (ctx.get_ally_lowest and ctx.get_ally_lowest())
      if ally and ctx.cast_spell_on then return ctx.cast_spell_on(20473, ally) end
      if ctx.target and ctx.target.is_enemy and ctx.cast_spell_on then return ctx.cast_spell_on(20473, ctx.target) end
      return false
    end,
  })
end


