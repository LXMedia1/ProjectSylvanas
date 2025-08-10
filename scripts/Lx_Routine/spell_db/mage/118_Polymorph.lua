-- Polymorph (ID: 118)
-- Crowd control; use when context requests CC
return function(engine)
  engine:register_spell({
    id = 118,
    name = "Polymorph",
    priority = 65,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(118) then return false end
      if ctx.should_cc and ctx.should_cc(ctx.target) then return true end
      return false
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on and ctx.target then return ctx.cast_spell_on(118, ctx.target) end
      return false
    end,
  })
end


