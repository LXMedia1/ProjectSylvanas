-- Internal routine engine (plugin, not exposed on _G)
local function create_engine()
  local engine = {
    debuglog = false,
    mode = "pve",
    is_running = false,
    spells = {},
    profile = nil,
    context_provider = nil,
    controller = nil,
  }

  function engine:set_debuglog(v)
    self.debuglog = not not v
  end

  function engine:set_mode(mode)
    self.mode = mode or "pve"
  end

  function engine:set_profile(profile)
    -- profile may include: class, spec, level, talents
    self.profile = profile
  end

  function engine:set_context_provider(fn)
    -- fn: function() -> ctx table with runtime helpers and game state
    self.context_provider = fn
  end

  function engine:register_spell(spell_definition)
    if type(spell_definition) ~= "table" or not spell_definition.id then
      if self.debuglog then core.log_warning("[Lx_Routine] invalid spell definition") end
      return false
    end
    table.insert(self.spells, spell_definition)
    return true
  end

  function engine:load_class(class_name)
    local ok, loaders = pcall(require, 'spell_db/loader')
    if not ok or type(loaders) ~= 'table' then
      if self.debuglog then core.log_error("[Lx_Routine] failed to load spell loader") end
      return false
    end
    local key = string.upper(class_name or "")
    local loader = loaders[key]
    if not loader then
      if self.debuglog then core.log_warning("[Lx_Routine] no spell loader for class: " .. key) end
      return false
    end
    local ok_loader, err = pcall(loader, self)
    if not ok_loader then
      if self.debuglog then core.log_error("[Lx_Routine] loader error for class " .. key .. ": " .. tostring(err)) end
      return false
    end
    return true
  end

  function engine:start()
    self.is_running = true
    if not self.controller then
      local Controller = require('Lx_Routine/controller')
      self.controller = Controller.new(self)
      self.controller:start()
    end
    return true
  end

  function engine:stop()
    self.is_running = false
    return true
  end

  local function build_ctx(self_engine)
    local ctx = {}
    if self_engine.context_provider then
      local ok, provided = pcall(self_engine.context_provider)
      if ok and type(provided) == 'table' then
        for k, v in pairs(provided) do
          ctx[k] = v
        end
      end
    end
    -- Fallbacks: auto‑wire from globals (_G/core) if not provided
    local c = rawget(_G, 'core')
    if c then
      ctx.get_player = ctx.get_player or function() return c.object_manager and c.object_manager.get_local_player() or nil end
      ctx.group_members = ctx.group_members or (c.group and c.group.members)
      ctx.enemies = ctx.enemies or (c.object_manager and c.object_manager.get_enemies)
      ctx.distance_to = ctx.distance_to or (c.navigation and c.navigation.distance_to)
      ctx.in_combat = ctx.in_combat or (c.player and c.player.in_combat)
      ctx.can_cast = ctx.can_cast or (c.spell and c.spell.can_cast)
      ctx.is_in_range = ctx.is_in_range or (c.spell and c.spell.is_in_range)
      ctx.requires_los = ctx.requires_los or (c.spell and c.spell.has_los)
      ctx.can_cast_while_moving = ctx.can_cast_while_moving or (c.spell and c.spell.can_cast_while_moving)
      ctx.cast_spell = ctx.cast_spell or (c.spell and c.spell.cast)
      ctx.cast_spell_on = ctx.cast_spell_on or (c.spell and c.spell.cast_on)
      ctx.has_buff = ctx.has_buff or (c.auras and c.auras.has_buff)
      ctx.has_debuff = ctx.has_debuff or (c.auras and c.auras.has_debuff)
      ctx.aura_remaining = ctx.aura_remaining or (c.auras and c.auras.remaining)
      ctx.expected_damage_in = ctx.expected_damage_in or (c.combat and c.combat.expected_damage_in)
      ctx.incoming_dps = ctx.incoming_dps or (c.combat and c.combat.incoming_dps)
      ctx.execute_threshold = ctx.execute_threshold or (c.combat and c.combat.execute_threshold)
      ctx.get_ally_lowest = ctx.get_ally_lowest or (c.heal and c.heal.lowest)
      ctx.get_ally_urgent = ctx.get_ally_urgent or (c.heal and c.heal.urgent)
      ctx.get_ally_critical = ctx.get_ally_critical or (c.heal and c.heal.critical)
      ctx.get_tank = ctx.get_tank or (c.heal and c.heal.tank)
      ctx.get_tank_urgent = ctx.get_tank_urgent or (c.heal and c.heal.tank_urgent)
      ctx.count_allies_below = ctx.count_allies_below or (c.heal and c.heal.count_below)
      ctx.enemies_close = ctx.enemies_close or (c.combat and c.combat.enemies_close)
      ctx.allies_close = ctx.allies_close or (c.combat and c.combat.allies_close)
      ctx.is_boss_or_elite = ctx.is_boss_or_elite or (c.combat and c.combat.is_boss_or_elite)
      ctx.set_target = ctx.set_target or (c.target and c.target.set)
      ctx.face = ctx.face or (c.player and c.player.face)
      ctx.move_to = ctx.move_to or (c.navigation and c.navigation.move_to)
      ctx.time_to_die = ctx.time_to_die or (c.combat and c.combat.time_to_die)
      ctx.gcd_remaining = ctx.gcd_remaining or (c.spell and c.spell.gcd_remaining)
      -- Healing helpers fallback to internal module
      if (not ctx.get_ally_lowest) or (not ctx.get_ally_urgent) or (not ctx.get_ally_critical) or (not ctx.get_ally_dispellable) or (not ctx.get_ally_to_res) then
        local Heal = require('Lx_Routine/healing')
        ctx.get_ally_lowest = ctx.get_ally_lowest or function() return Heal.find_ally_lowest(ctx) end
        ctx.get_ally_urgent = ctx.get_ally_urgent or function() return Heal.find_ally_critical(ctx) end
        ctx.get_ally_critical = ctx.get_ally_critical or function() return Heal.find_ally_critical(ctx) end
        ctx.get_ally_dispellable = ctx.get_ally_dispellable or function() return Heal.find_ally_dispellable(ctx) end
        ctx.get_ally_to_res = ctx.get_ally_to_res or function() return Heal.find_ally_to_res(ctx) end
      end
    end
    -- Attach internal prediction if host doesn't provide
    if (not ctx.expected_damage_in) or (not ctx.incoming_dps) or (not ctx.time_to_die) then
      local pred = require('Lx_Routine/prediction')
      pred.start()
      ctx.expected_damage_in = ctx.expected_damage_in or pred.expected_damage_in
      ctx.incoming_dps = ctx.incoming_dps or pred.incoming_dps
      ctx.time_to_die = ctx.time_to_die or pred.time_to_die
    end
    ctx.engine = self_engine
    ctx.log = function(msg)
      if self_engine.debuglog and core and core.log then
        core.log('[Lx_Routine] ' .. tostring(msg))
      end
    end
    return ctx
  end

  -- Single update callback; engine runs only when is_running=true
  core.register_on_update_callback(function()
    if not engine.is_running then return end
    if not engine.spells or #engine.spells == 0 then return end

    local ctx = build_ctx(engine)

    -- Sort by priority descending (stable enough each tick)
    table.sort(engine.spells, function(a, b)
      local pa = a.priority or 0
      local pb = b.priority or 0
      if pa == pb then
        return (a.id or 0) < (b.id or 0)
      end
      return pa > pb
    end)

    for i = 1, #engine.spells do
      local s = engine.spells[i]

      local usable = true
      if s.is_usable then
        local ok, res = pcall(s.is_usable, ctx)
        usable = ok and res == true
      end

      if usable then
        local should = true
        if s.should_use then
          local ok, res = pcall(s.should_use, ctx)
          should = ok and res == true
        end

        if should and s.execute then
          local ok, casted = pcall(s.execute, ctx)
          if ok and casted == true then
            -- Executed a spell this tick; stop evaluating further
            return
          end
        end
      end
    end
  end)

  return engine
end

-- Instantiate and start automatically as a plugin (no _G exposure)
local engine = create_engine()

-- Try to detect class/spec from _G.core and load relevant spells
do
  local c = rawget(_G, 'core')
  local class_name
  local spec_name
  if c and c.player and c.player.get_class_name then
    class_name = c.player.get_class_name()
    if c.player.get_spec_name then spec_name = c.player.get_spec_name() end
  elseif c and c.object_manager and c.object_manager.get_local_player then
    local me = c.object_manager.get_local_player()
    if me and me.get_class_name then class_name = me:get_class_name() end
    if me and me.get_spec_name then spec_name = me:get_spec_name() end
  end
  if spec_name then
    engine:set_profile({ class = class_name, spec = spec_name })
  elseif class_name then
    engine:set_profile({ class = class_name })
  end
  if class_name then
    engine:load_class(class_name)
  else
    -- Fallback: try common classes progressively if detection unavailable
    engine:load_class('Priest')
  end
end

engine:start()


