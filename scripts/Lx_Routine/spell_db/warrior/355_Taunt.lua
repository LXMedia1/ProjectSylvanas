-- Taunt (ID: 355)
-- Protection utility; force target to attack you
return function(engine)
  engine:register_spell({
    id = 355,
    name = "Taunt",
    priority = 110,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(355) then return false end
      if ctx.should_taunt and ctx.should_taunt(ctx.target) then return true end
      return false
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(355, ctx.target) end
      return false
    end,
  })
end


