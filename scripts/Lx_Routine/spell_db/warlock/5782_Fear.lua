-- Fear (ID: 5782)
-- Crowd control
return function(engine)
  engine:register_spell({
    id = 5782,
    name = "Fear",
    priority = 65,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id('Fear') or 5782)) or 5782
      if ctx.can_cast and not ctx.can_cast(sid) then return false end
      if ctx.should_cc and ctx.should_cc(ctx.target) then return true end
      return false
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id('Fear') or 5782)) or 5782
      if ctx.cast_spell_on then return ctx.cast_spell_on(sid, ctx.target) end
      return false
    end,
  })
end


