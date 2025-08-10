-- Spell Reflection (ID: 23920)
-- Reflects magic spells briefly
return function(engine)
  engine:register_spell({
    id = 23920,
    name = "Spell Reflection",
    priority = 160,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(23920) then return false end
      return true
    end,

    should_use = function(ctx)
      return ctx.incoming_spell and ctx.incoming_spell()
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(23920) end
      return false
    end,
  })
end


