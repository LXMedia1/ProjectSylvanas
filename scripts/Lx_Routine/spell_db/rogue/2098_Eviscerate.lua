-- Eviscerate (ID: 2098)
-- Finisher (Sub/Outlaw with CP)
return function(engine)
  engine:register_spell({
    id = 2098,
    name = "Eviscerate",
    priority = 95,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(2098) then return false end
      return true
    end,

    should_use = function(ctx)
      if ctx.combo_points and ctx.combo_points() then
        return ctx.combo_points() >= 5
      end
      return false
    end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(2098, ctx.target) end
      return false
    end,
  })
end


