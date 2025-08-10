-- Purify (ID: 527)
-- Friendly dispel: removes all Magic effects (and Disease) from a friendly target
return function(engine)
  engine:register_spell({
    id = 527,
    name = "Purify",
    priority = 93,

    is_usable = function(ctx)
      if not ctx then return false end
      local ally = (ctx.get_ally_dispellable and ctx.get_ally_dispellable()) or nil
      if not ally then return false end
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Purify") or 527)) or 527
      if ctx.can_cast and not ctx.can_cast(sid) then return false end
      return true
    end,

    should_use = function(ctx)
      local ally = (ctx.get_ally_dispellable and ctx.get_ally_dispellable()) or nil
      return ally ~= nil
    end,

    execute = function(ctx)
      local ally = (ctx.get_ally_dispellable and ctx.get_ally_dispellable()) or nil
      if ally and ctx.cast_spell_on then
        local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Purify") or 527)) or 527
        return ctx.cast_spell_on(sid, ally)
      end
      return false
    end,
  })
end


