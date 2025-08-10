-- Power Word: Shield (ID: 17)
-- Defensive; cast when player lacks Weakened Soul (or equivalent) and health below threshold
return function(engine)
  engine:register_spell({
    id = 17,
    name = "Power Word: Shield",
    priority = 100,

    is_usable = function(ctx)
      if not ctx or not ctx.player then return false end
      if ctx.can_cast and not ctx.can_cast(17) then return false end

      -- If host exposes an explicit absorb gating helper, use it
      if ctx.can_apply_absorb and not ctx.can_apply_absorb(17, ctx.player) then
        return false
      end

      -- If already heavily shielded and no refresh allowed, skip
      local current_absorb = (ctx.player.absorb_remaining) or (ctx.absorb_remaining and ctx.absorb_remaining(ctx.player)) or 0
      if current_absorb and current_absorb > 0 then
        if ctx.can_recast_absorb then
          if not ctx.can_recast_absorb(17, ctx.player) then return false end
        end
      end

      return true
    end,

    should_use = function(ctx)
      -- Mathematical decision: cast if a significant portion of the absorb will be consumed within a short horizon
      local horizon
      local gcd = (ctx.gcd_remaining and ctx.gcd_remaining()) or 0
      horizon = math.max(1.5, math.min(3.0, gcd + 1.5))

      local incoming
      if ctx.expected_damage_in then
        incoming = ctx.expected_damage_in(ctx.player, horizon)
      else
        local dps = (ctx.incoming_dps and ctx.incoming_dps(ctx.player)) or 0
        incoming = dps * horizon
      end
      if not incoming or incoming <= 0 then return false end

      local current_absorb = (ctx.player.absorb_remaining) or (ctx.absorb_remaining and ctx.absorb_remaining(ctx.player)) or 0
      if current_absorb >= incoming then
        return false
      end

      local absorb = (ctx.spell_absorb_value and ctx.spell_absorb_value(17, ctx.player))
        or (ctx.estimate_absorb and ctx.estimate_absorb(17, ctx.player))
        or nil
      if not absorb or absorb <= 0 then return false end

      -- Missing mitigation in the horizon
      local deficit = incoming - (current_absorb or 0)
      if deficit <= 0 then return false end

      -- Require at least 50% of the new absorb to be consumed within the horizon to avoid waste
      return (absorb * 0.5) <= deficit
    end,

    execute = function(ctx)
      if ctx.cast_spell then
        return ctx.cast_spell(17)
      end
      return false
    end,
  })
end


