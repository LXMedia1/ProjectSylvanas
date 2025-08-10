-- Thunder Clap (ID: 6343)
-- AoE damage and slow; Protection/Arms AoE builder
return function(engine)
  engine:register_spell({
    id = 6343,
    name = "Thunder Clap",
    priority = 80,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.can_cast and not ctx.can_cast(6343) then return false end
      local n = ctx.enemies_close and ctx.enemies_close(8) or 0
      return n >= 2
    end,

    should_use = function(ctx) return true end,

    execute = function(ctx)
      if ctx.cast_spell then return ctx.cast_spell(6343) end
      return false
    end,
  })
end


