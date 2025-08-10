-- Spinning Crane Kick (ID: 101546)
-- Windwalker AoE
return function(engine)
  engine:register_spell({
    id = 101546,
    name = "Spinning Crane Kick",
    priority = 80,

    is_usable = function(ctx)
      if not ctx then return false end
      if ctx.can_cast and not ctx.can_cast(101546) then return false end
      if ctx.is_spec and not ctx.is_spec('Windwalker') then return false end
      if (ctx.engine and ctx.engine.profile and ctx.engine.profile.spec and string.lower(ctx.engine.profile.spec) ~= 'windwalker') and not ctx.is_spec then return false end
      local n = ctx.enemies_close and ctx.enemies_close(8) or 0
      return n >= 3
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(101546) end
      return false
    end,
  })
end


