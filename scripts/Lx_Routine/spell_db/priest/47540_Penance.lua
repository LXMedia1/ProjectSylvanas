-- Penance (ID: 47540)
-- Discipline signature; damage (offensive) or healing (defensive) channel.
return function(engine)
  engine:register_spell({
    id = 47540,
    name = "Penance",
    priority = 97,

    is_usable = function(ctx)
      if not ctx or (ctx.can_cast and not ctx.can_cast(47540)) then return false end
      return true
    end,

    should_use = function(ctx)
      -- Prefer healing if someone is in danger, otherwise offensive on enemy target
      local ally = ctx.get_ally_urgent and ctx.get_ally_urgent()
      if ally then return true end
      local t = ctx.target
      return t and t.is_enemy and not t.is_dead
    end,

    execute = function(ctx)
      local ally = ctx.get_ally_urgent and ctx.get_ally_urgent()
      if ally and ctx.cast_spell_on then
        return ctx.cast_spell_on(47540, ally)
      end
      if ctx.target and ctx.target.is_enemy and not ctx.target.is_dead then
        if ctx.cast_spell_on then
          return ctx.cast_spell_on(47540, ctx.target)
        end
      end
      return false
    end,
  })
end


