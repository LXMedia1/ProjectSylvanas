-- Leap of Faith (ID: 73325)
-- Grip an ally to your location; use on isolated ally in danger
return function(engine)
  engine:register_spell({
    id = 73325,
    name = "Leap of Faith",
    priority = 60,

    is_usable = function(ctx)
      if not ctx then return false end
      local ally = ctx.get_ally_to_grip and ctx.get_ally_to_grip()
      if not ally then return false end
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Leap of Faith") or 73325)) or 73325
      if ctx.can_cast and not ctx.can_cast(sid) then return false end
      return true
    end,

    should_use = function(ctx)
      return ctx.get_ally_to_grip and (ctx.get_ally_to_grip() ~= nil)
    end,

    execute = function(ctx)
      local ally = ctx.get_ally_to_grip and ctx.get_ally_to_grip()
      if ally and ctx.cast_spell_on then
        local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Leap of Faith") or 73325)) or 73325
        return ctx.cast_spell_on(sid, ally)
      end
      return false
    end,
  })
end


