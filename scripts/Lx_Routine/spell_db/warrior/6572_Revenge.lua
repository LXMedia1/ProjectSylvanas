-- Revenge (ID: 6572)
-- Protection proc/spender
return function(engine)
  engine:register_spell({
    id = 6572,
    name = "Revenge",
    priority = 90,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(6572) then return false end
      local d = ctx.distance_to and ctx.distance_to(ctx.target)
      return d and d <= 8
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell_on then return ctx.cast_spell_on(6572, ctx.target) end
      return false
    end,
  })
end


