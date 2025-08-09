### Lx_Nav — Setup and Usage

A lightweight, standalone navigation library with pathfinding and human‑like movement for Lua 5.1 environments.

- **Target runtime**: Lua 5.1
- **I/O policy**: Uses only `scripts/.api` (no `os.*`, `io.*`, or `print`)
- **Rendering/logging by default**: Off
- **Menu**: None built‑in (library only)

### Requirements
- The mmaps navigation data (mmap + mmtile files). Get them from the Arctium data index under the “Master” directory.
  - Source: [Arctium Navigation Data](https://tc.arctium.io)

### Install navigation data
1. Create the data folder if it does not exist:
   - `scripts_data/mmaps`
2. Download the mmaps package from the “Master” directory on the Arctium site and extract:
   - Place the top‑level `*.mmap` file(s) into `scripts_data/mmaps/`
   - Place all `*.mmtile` files into `scripts_data/mmaps/`
3. Verify the folder now contains files like:
   - `scripts_data/mmaps/0000.mmap`
   - `scripts_data/mmaps/000000.mmtile`, `scripts_data/mmaps/000001.mmtile`, …

Notes:
- The library reads from `mmaps/` via the core data API, which maps to `scripts_data/mmaps` on disk.
- If the folder is missing or empty, loading will fail.

### Quick start
```lua
-- Initialize once (exposes a simple control surface)
local nav = _G.Lx_Nav.init()

-- Optional toggles (all false by default)
nav.set_show_path(false)   -- draw path
nav.set_debuglog(false)    -- verbose logs
nav.set_use_look_at(false) -- face target using look_at; when off, uses key turns

-- Move to a point with pathfinding
nav.move_to(vec3.new(x, y, z), false, function(success)
  if success then
    -- reached destination
  else
    -- stopped or failed
  end
end)

-- Direct guidance (no A*)
nav.move_to(vec3.new(x, y, z), true)

-- Query the current/last computed path
local path = nav.get_path()            -- returns array of vec3 nodes
-- Or compute a path from a custom start to an end
local path2 = nav.get_path(vec3.new(sx, sy, sz), vec3.new(ex, ey, ez))

-- Stop movement immediately
nav.stop()
```

### How it works (brief)
- Loads mmaps tiles around the player and merges polygons across tiles.
- Builds a graph and computes an A* path; path is followed with human‑like steering.

### Troubleshooting
- "Failed to load 0000.mmap": The `scripts_data/mmaps` folder is missing or empty. Ensure the files are extracted correctly.
- No path across regions: Ensure you have the corresponding `*.mmtile` files for the area you are testing.
- Movement seems to hug edges: Tune the safety margin (if exposed in your UI) or verify you have up‑to‑date tiles from the Arctium Master set.

### Public API
See `@docs/Lx_Nav_API.md` for the complete surface of `_G.Lx_Nav`.

### Attribution
- Navigation data courtesy of Arctium. See their index: [Arctium Navigation Data](https://tc.arctium.io)
- This project is not affiliated with Blizzard Entertainment.
