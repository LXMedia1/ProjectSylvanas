-- Create Healthstone (ID: 6201)
-- Utility: ensure healthstone available out of combat
return function(engine)
  engine:register_spell({
    id = 6201,
    name = "Create Healthstone",
    priority = 10,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.in_combat and ctx.in_combat() then return false end
      if ctx.can_cast and not ctx.can_cast(6201) then return false end
      if ctx.has_item and ctx.has_item('Healthstone') then return false end
      return true
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(6201) end
      return false
    end,
  })
end


