-- Power Word: Fortitude (ID: 21562)
-- Party/raid buff; maintain out of combat.
return function(engine)
  engine:register_spell({
    id = 21562,
    name = "Power Word: Fortitude",
    priority = 30,

    is_usable = function(ctx)
      if not ctx or (ctx.can_cast and not ctx.can_cast(21562)) then return false end
      if ctx.in_combat and ctx.in_combat() then
        -- Can still cast in combat, but we prefer out-of-combat
      end
      return true
    end,

    should_use = function(ctx)
      if ctx.group_members then
        local members = ctx.group_members()
        for i = 1, #members do
          if not (ctx.has_buff and ctx.has_buff(members[i], 21562)) then
            return true
          end
        end
        return false
      end
      -- Solo: keep on self
      if ctx.get_player and ctx.has_buff then
        local me = ctx.get_player()
        return me and not ctx.has_buff(me, 21562)
      end
      return false
    end,

    execute = function(ctx)
      if ctx.group_members then
        local members = ctx.group_members()
        for i = 1, #members do
          if ctx.cast_spell_on and (not ctx.has_buff or not ctx.has_buff(members[i], 21562)) then
            return ctx.cast_spell_on(21562, members[i])
          end
        end
      end
      if ctx.get_player and ctx.cast_spell_on then
        return ctx.cast_spell_on(21562, ctx.get_player())
      end
      return false
    end,
  })
end


