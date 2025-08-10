-- Demonic Power (Tyrant) (ID: 265187)
-- Demonology: Summon Demonic Tyrant
return function(engine)
  engine:register_spell({
    id = 265187,
    name = "Summon Demonic Tyrant",
    priority = 100,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(265187) then return false end
      if ctx.is_spec and not ctx.is_spec('Demonology') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'demonology') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx) return ctx.is_burst_window and ctx.is_burst_window() end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(265187) end
      return false
    end,
  })
end


