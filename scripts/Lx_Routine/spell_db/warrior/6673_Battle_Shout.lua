-- Battle Shout (ID: 6673)
-- Group attack power buff; maintain
return function(engine)
  engine:register_spell({
    id = 6673,
    name = "Battle Shout",
    priority = 30,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(6673) then return false end
      return true
    end,

    should_use = function(ctx)
      if ctx.group_members then
        local members = ctx.group_members()
        for i = 1, #members do
          if not (ctx.has_buff and ctx.has_buff(members[i], 6673)) then return true end
        end
        return false
      end
      local me = ctx.get_player and ctx.get_player()
      if me and ctx.has_buff then return not ctx.has_buff(me, 6673) end
      return false
    end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(6673) end
      return false
    end,
  })
end


