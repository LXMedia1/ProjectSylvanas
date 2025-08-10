-- Arcane Shot (ID: 185358)
-- Marksmanship/BM focus dump
return function(engine)
  engine:register_spell({
    id = 185358,
    name = "Arcane Shot",
    priority = 50,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(185358) then return false end
      return true
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(185358, ctx.target) end
      return false
    end,
  })
end


