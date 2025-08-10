-- Rupture (ID: 1943)
-- Bleed finisher
return function(engine)
  engine:register_spell({
    id = 1943,
    name = "Rupture",
    priority = 88,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(1943) then return false end
      return true
    end,

    should_use = function(ctx)
      if ctx.combo_points and ctx.combo_points() then
        if ctx.aura_remaining then
          local remain = ctx.aura_remaining(ctx.target, 1943)
          return ctx.combo_points() >= 5 and ((not remain) or remain <= 4.0)
        end
        return ctx.combo_points() >= 5
      end
      return false
    end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(1943, ctx.target) end
      return false
    end,
  })
end


