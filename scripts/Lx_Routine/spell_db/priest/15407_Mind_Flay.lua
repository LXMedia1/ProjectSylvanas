-- Mind Flay (ID: 15407)
-- Shadow filler channel. Prefer when no higher priority spell is available.
return function(engine)
  engine:register_spell({
    id = 15407,
    name = "Mind Flay",
    priority = 40,

    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.target.is_dead or not ctx.target.is_enemy then return false end
      if ctx.requires_los and not ctx.requires_los(15407, ctx.target) then return false end
      if ctx.is_in_range and not ctx.is_in_range(15407, ctx.target) then return false end
      if ctx.can_cast and not ctx.can_cast(15407) then return false end
      if ctx.player and ctx.player.is_moving then
        if ctx.can_cast_while_moving and ctx.can_cast_while_moving(15407) then else return false end
      end
      return true
    end,

    should_use = function(ctx)
      return true
    end,

    execute = function(ctx)
      if ctx.cast_spell_on and ctx.target then
        return ctx.cast_spell_on(15407, ctx.target)
      elseif ctx.cast_spell then
        return ctx.cast_spell(15407)
      end
      return false
    end,
  })
end


