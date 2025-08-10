-- Hex (ID: 51514)
-- CC polymorph-style
return function(engine)
  engine:register_spell({
    id = 51514,
    name = "Hex",
    priority = 100,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(51514) then return false end
      return ctx.should_cc and ctx.should_cc(ctx.target)
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(51514, ctx.target) end
      return false
    end,
  })
end


