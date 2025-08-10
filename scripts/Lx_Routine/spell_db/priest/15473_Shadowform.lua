-- Shadowform (ID: 15473 old; Retail uses a different ID). Resolve by name if possible.
-- Maintain form while in Shadow spec
return function(engine)
  engine:register_spell({
    id = 15473,
    name = "Shadowform",
    priority = 41,

    is_usable = function(ctx)
      if not ctx or not ctx.get_player then return false end
      local me = ctx.get_player()
      if not me then return false end
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Shadowform") or 15473)) or 15473
      if ctx.has_buff and ctx.has_buff(me, sid) then return false end
      if ctx.is_spec and not ctx.is_spec('Shadow') then return false end
      if ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'shadow' then
        return false
      end
      if ctx.can_cast and not ctx.can_cast(sid) then return false end
      return true
    end,

    should_use = function(ctx)
      return true
    end,

    execute = function(ctx)
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Shadowform") or 15473)) or 15473
      if ctx.cast_spell then return ctx.cast_spell(sid) end
      return false
    end,
  })
end


