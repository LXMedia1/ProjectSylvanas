Lx_Routine API

Global
- `_G.Lx_Routine.init()` → returns an engine with:
  - `set_debuglog(boolean)` – enable/disable debug logging (off by default)
  - `set_mode(string)` – currently `"pve"` (default)
  - `set_profile(table)` – optional metadata: `{ class, spec, level, talents }`
  - `set_context_provider(function)` – inject a function returning runtime context used by spells
  - `register_spell(table)` – register a spell definition
  - `load_class(string)` – loads a class package (e.g. `"Priest"`)
  - `start()` / `stop()` – control evaluation loop

Spell definition (table)
- `id:number` – spell ID (required)
- `name:string` – name (recommended)
- `priority:number` – higher runs first (default 0)
- `is_usable(ctx):boolean` – gating checks: resources, movement, range, LoS, cooldowns
- `should_use(ctx):boolean` – tactical/rotational decision (e.g., fillers vs. procs)
- `execute(ctx):boolean` – perform the cast; return true on successful issuance

Context provider contract (examples)
```lua
return {
  player = { is_moving = boolean },
  target = { is_enemy = boolean, is_dead = boolean },
  can_cast = function(spell_id) -> boolean end,
  is_in_range = function(spell_id, unit) -> boolean end,
  requires_los = function(spell_id, unit) -> boolean end,
  can_cast_while_moving = function(spell_id) -> boolean end,
  cast_spell_on = function(spell_id, unit) -> boolean end,
  cast_spell = function(spell_id) -> boolean end,
}
```

Notes
- The engine does not manage GCD or cooldown tracking itself. Prefer authoritative `can_cast` from the host API.
- Logging/UI are disabled by default to keep the library clean.


