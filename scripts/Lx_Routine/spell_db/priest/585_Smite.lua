-- Smite (ID: 585)
-- Generic leveling/PvE filler: cast when target is a valid enemy, in range, and we can cast
return function(engine)
  engine:register_spell({
    id = 585,
    name = "Smite",
    priority = 45,

    -- ctx is provided by the engine's context_provider()
    -- Expected helpers if available:
    --   ctx.player -> { is_moving:boolean }
    --   ctx.target -> { is_enemy:boolean, is_dead:boolean }
    --   ctx.can_cast(spell_id):boolean
    --   ctx.is_in_range(spell_id, target):boolean
    --   ctx.requires_los(spell_id, target):boolean
    --   ctx.can_cast_while_moving(spell_id):boolean
    --   ctx.cast_spell(spell_id):boolean
    --   ctx.cast_spell_on(spell_id, target):boolean
    is_usable = function(ctx)
      if not ctx or not ctx.target then return false end
      if ctx.target.is_dead then return false end
      if not ctx.target.is_enemy then return false end
      if ctx.requires_los and not ctx.requires_los(585, ctx.target) then return false end
      if ctx.is_in_range and not ctx.is_in_range(585, ctx.target) then return false end
      if ctx.can_cast and not ctx.can_cast(585) then return false end
      if ctx.player and ctx.player.is_moving then
        if ctx.can_cast_while_moving and ctx.can_cast_while_moving(585) then
          -- allowed while moving (e.g., special buff)
        else
          return false
        end
      end
      return true
    end,

    should_use = function(ctx)
      -- Filler: always true when usable
      return true
    end,

    execute = function(ctx)
      if ctx.cast_spell_on and ctx.target then
        return ctx.cast_spell_on(585, ctx.target)
      elseif ctx.cast_spell then
        return ctx.cast_spell(585)
      end
      return false
    end,
  })
end


