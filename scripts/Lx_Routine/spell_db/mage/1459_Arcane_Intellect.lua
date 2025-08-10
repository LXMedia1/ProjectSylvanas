-- Arcane Intellect (ID: 1459)
-- Party/raid Intellect buff; maintain
return function(engine)
  engine:register_spell({
    id = 1459,
    name = "Arcane Intellect",
    priority = 30,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(1459) then return false end
      return true
    end,

    should_use = function(ctx)
      if ctx.group_members then
        local members = ctx.group_members()
        for i = 1, #members do
          if not (ctx.has_buff and ctx.has_buff(members[i], 1459)) then return true end
        end
        return false
      end
      local me = ctx.get_player and ctx.get_player()
      if me and ctx.has_buff then return not ctx.has_buff(me, 1459) end
      return false
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(1459) end
      return false
    end,
  })
end


