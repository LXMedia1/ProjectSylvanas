### Lx_Nav — Lightweight NavMesh Pathfinding for Project Sylvanas

Human‑like navigation on retail data using mmaps. Computes smooth A* paths across multiple tiles and follows them with natural keyboard steering (optional look_at), obstacle‑aware guidance, and mounted tuning. Designed for Lua 5.1 sandbox: no external I/O, time‑sliced jobs, and minimal overhead.

### Highlights
- A* pathfinding across merged polygon graph (multi‑tile)
- Smoothed corridor (simplify + Chaikin) for clean movement
- Human‑like driver: keyboard turns, optional `look_at`, obstacle probing
- Path overlay toggle (draws even when other debug visuals are off)
- Automatic tile loading around player and distance‑based eviction to prevent memory bloat
- Incremental, budgeted builds for mesh and graph (stutter‑free)
- Simple API surface exposed via `_G.Lx_Nav`

### Requirements
1) Download the mmaps navigation data from the Arctium index (Master set): [Arctium Navigation Data](https://tc.arctium.io)
2) Create folder `scripts_data/mmaps`
3) Place `*.mmap` and all `*.mmtile` files inside `scripts_data/mmaps`

### Quick Start
```lua
local nav = _G.Lx_Nav.init()
nav.set_show_path(true)                -- optional: draw path overlay
nav.move_to(vec3.new(x, y, z), false)  -- compute path and move
-- nav.stop()                          -- stop movement immediately
```

### Defaults (performance)
- `tile_load_radius = 1` (load small neighborhood)
- `tile_keep_radius = 2` (evict tiles farther than this; rebuilds graph)
- Path auto‑hides on arrival
- Enable debug logs via `nav.set_debuglog(true)`; eviction logs will be printed

### Version
- 1.1 — Path overlay decoupled from debug gate, auto‑hide at arrival, tile eviction with logging, docs/notes updated


