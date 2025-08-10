-- Purifying Brew (ID: 119582)
-- Brewmaster: purify staggered damage
return function(engine)
  engine:register_spell({
    id = 119582,
    name = "Purifying Brew",
    priority = 130,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(119582) then return false end
      if ctx.is_spec and not ctx.is_spec('Brewmaster') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'brewmaster') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx)
      if ctx.stagger_level then
        local lvl = ctx.stagger_level()
        return lvl and (lvl == 'heavy' or lvl == 'moderate')
      end
      return false
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(119582) end
      return false
    end,
  })
end


