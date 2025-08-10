-- Fire Blast (ID: 108853)
-- Fire instant; crits guaranteed during Combustion, used to fish Hot Streak
return function(engine)
  engine:register_spell({
    id = 108853,
    name = "Fire Blast",
    priority = 93,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(108853) then return false end
      if ctx.is_spec and not ctx.is_spec('Fire') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'fire') and not ctx.is_spec then return false end
      return true
    end,

    should_use = function(ctx)
      -- Prefer during Combustion or with Heating Up/Hot Streak buffs if available
      local me = ctx.get_player and ctx.get_player() or nil
      if me and ctx.has_buff then
        if ctx.has_buff(me, 190319) then return true end -- Combustion
        if ctx.has_buff(me, 48107) or ctx.has_buff(me, 48108) then return true end -- Heating Up / Hot Streak
      end
      return true
    end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(108853, ctx.target) end
      return false
    end,
  })
end


