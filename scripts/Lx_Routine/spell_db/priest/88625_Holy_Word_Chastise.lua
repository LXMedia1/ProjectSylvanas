-- Holy Word: Chastise (ID: 88625)
-- Holy instant damage/CC; use on pull or as a high-priority nuke.
return function(engine)
  engine:register_spell({
    id = 88625,
    name = "Holy Word: Chastise",
    priority = 99,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.target.is_dead or not ctx.target.is_enemy then return false end
      if ctx.requires_los and not ctx.requires_los(88625, ctx.target) then return false end
      if ctx.is_in_range and not ctx.is_in_range(88625, ctx.target) then return false end
      if ctx.can_cast and not ctx.can_cast(88625) then return false end
      return true
    end,

    should_use = function(ctx)
      return true
    end,

    execute = function(ctx)
      if ctx.cast_spell_on and ctx.target then
        return ctx.cast_spell_on(88625, ctx.target)
      elseif ctx.cast_spell then
        return ctx.cast_spell(88625)
      end
      return false
    end,
  })
end


