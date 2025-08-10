-- Power Infusion (ID: 10060)
-- Haste cooldown; use on self or assigned ally during burst windows
return function(engine)
  engine:register_spell({
    id = 10060,
    name = "Power Infusion",
    priority = 84,

    is_usable = function(ctx)
      if not ctx then return false end
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Power Infusion") or 10060)) or 10060
      if ctx.can_cast and not ctx.can_cast(sid) then return false end
      return true
    end,

    should_use = function(ctx)
      -- Use during raid burst or on self if personal burst detected
      if ctx.is_burst_window and ctx.is_burst_window() then return true end
      return false
    end,

    execute = function(ctx)
      local sid = (ctx.resolve_spell_id and (ctx.resolve_spell_id("Power Infusion") or 10060)) or 10060
      if ctx.cast_spell then return ctx.cast_spell(sid) end
      return false
    end,
  })
end


