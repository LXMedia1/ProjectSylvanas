### Lx_Routine — Adaptive PvE Fight Routine (Retail)

An extensible Lua 5.1 routine engine that adapts to level and supports all classes/races for PvE. Logic is sourced and validated against class guides on Wowhead.

- Target runtime: Lua 5.1
- I/O policy: Uses only `scripts/.api` (no `os.*`, `io.*`, or `print`)
- Logging/UI: Off by default; library-only surface
- Source for rotations and priorities: [Wowhead Class Guides](https://www.wowhead.com/guides/classes)

### Features
- Per-spell files under `scripts/Lx_Routine/spell_db/` (one file per spell ID)
- Simple priority engine with `is_usable`, `should_use`, and `execute` hooks
- Decoupled context via `set_context_provider(fn)` so game APIs are injected (no mocks)
- Class loaders to register spells incrementally
- Autonomous controller with smart target selection, engagement movement, and facing

### Current coverage (Priest)
- Utility/Buffs: Power Word: Fortitude (21562)
- Defensive: Power Word: Shield (17)
- Heals: Renew (139), Heal (2060), Flash Heal (2061), Prayer of Mending (33076), Power Word: Radiance (194509)
- Holy/Disc Damage: Holy Word: Chastise (88625), Holy Fire (14914), Smite (585)
- Shadow Damage/DoTs: Vampiric Touch (34914), Shadow Word: Pain (589), Mind Blast (8092), Mind Flay (15407), Shadowfiend (34433), Shadow Word: Death (32379)

### Quick start
```lua
local routine = _G.Lx_Routine.init()

-- Optional toggles
routine:set_debuglog(false)
routine:set_mode('pve')

-- Provide runtime/game context (wrap your core API here)
routine:set_context_provider(function()
  return {
    player = { is_moving = core.player and core.player.is_moving() or false },
    target = (core.target and core.target.get_current()) or nil,
    can_cast = function(spell_id) return core.spell and core.spell.can_cast(spell_id) end,
    is_in_range = function(spell_id, unit) return core.spell and core.spell.is_in_range(spell_id, unit) end,
    requires_los = function(spell_id, unit) return core.spell and core.spell.has_los(spell_id, unit) end,
    cast_spell_on = function(spell_id, unit) return core.spell and core.spell.cast_on(spell_id, unit) end,
    cast_spell = function(spell_id) return core.spell and core.spell.cast(spell_id) end,
  }
end)

-- Load a class spell package
routine:load_class('Priest')

-- Start the engine
routine:start()
```

Note: Function names above are placeholders. Wire them to your actual `scripts/.api`. The controller will attempt to select targets (`enemies()`), move (`move_to` or via `Lx_Nav` if present), and face targets (`face` or `core.input.look_at`).

### Spell file layout
- Path: `scripts/Lx_Routine/spell_db/<class>/<id>_<Name>.lua`
- Each file returns a function that receives `engine` and registers one spell:
```lua
return function(engine)
  engine:register_spell({
    id = 12345,
    name = "Spell Name",
    priority = 100,
    is_usable = function(ctx) return true end,
    should_use = function(ctx) return true end,
    execute = function(ctx) return ctx.cast_spell(12345) end,
  })
end
```

### Development notes
- Keep changes minimal and incremental; add spells gradually per class/spec.
- No mocks or fake datasets; always rely on live game APIs injected via the context provider.
- Avoid `error()` for control flow; report via `core.log/core.log_warning/core.log_error` and return values.
- Profiling: prefer CPU tick counters when available.

### Attribution
- Rotations and priorities are informed by Wowhead class guides: [Wowhead Class Guides](https://www.wowhead.com/guides/classes)


