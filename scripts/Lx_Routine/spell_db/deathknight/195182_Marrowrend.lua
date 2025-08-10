-- Marrowrend (ID: 195182)
-- Blood: generate Bone Shield
return function(engine)
  engine:register_spell({
    id = 195182,
    name = "Marrowrend",
    priority = 100,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(195182) then return false end
      if ctx.is_spec and not ctx.is_spec('Blood') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'blood') and not ctx.is_spec then return false end
      local d = ctx.distance_to and ctx.distance_to(ctx.target)
      return d and d <= 5
    end,

    should_use = function(ctx)
      -- Use when Bone Shield stacks low if available
      if ctx.buff_stacks then
        local me = ctx.get_player and ctx.get_player() or nil
        if me then
          local stacks = ctx.buff_stacks(me, 195181) -- Bone Shield
          return (not stacks) or stacks < 6
        end
      end
      return true
    end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(195182, ctx.target) end
      return false
    end,
  })
end


