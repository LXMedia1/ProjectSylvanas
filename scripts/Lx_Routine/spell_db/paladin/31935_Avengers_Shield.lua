-- Avenger's Shield (ID: 31935)
-- Protection ranged interrupt/silence + damage; high priority
return function(engine)
  engine:register_spell({
    id = 31935,
    name = "Avenger's Shield",
    priority = 115,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(31935) then return false end
      if ctx.is_spec and not ctx.is_spec('Protection') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'protection') and not ctx.is_spec then return false end
      if ctx.requires_los and not ctx.requires_los(31935, ctx.target) then return false end
      if ctx.is_in_range and not ctx.is_in_range(31935, ctx.target) then return false end
      return true
    end,

    should_use = function(ctx)
      if ctx.is_cast_interruptible and ctx.is_cast_interruptible(ctx.target) then return true end
      return true
    end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(31935, ctx.target) end
      return false
    end,
  })
end


