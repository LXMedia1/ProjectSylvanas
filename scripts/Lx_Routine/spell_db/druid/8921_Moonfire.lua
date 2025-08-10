-- Moonfire (ID: 8921)
-- Balance DoT; also Feral/Resto utility pull
return function(engine)
  engine:register_spell({
    id = 8921,
    name = "Moonfire",
    priority = 80,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(8921) then return false end
      return true
    end,

    should_use = function(ctx)
      if ctx.aura_remaining then
        local remain = ctx.aura_remaining(ctx.target, 8921)
        return (not remain) or remain <= 3.0
      end
      if ctx.has_debuff then return not ctx.has_debuff(ctx.target, 8921) end
      return true
    end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(8921, ctx.target) end
      return false
    end,
  })
end


