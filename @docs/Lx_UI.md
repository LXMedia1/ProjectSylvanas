### Lx_UI — Overview

Lx_UI is a modular UI system offering floating windows, precise input blocking, and persistence hooks, designed for the Lua 5.1 sandbox with `core.*` APIs.

Highlights
- Floating windows with centralized rendering.
- Input blocking helper (`Lx_UI.isInputBlocked()`).
- Menu integration to select launcher mode (palette/sidebar/topbar planned).

Usage
```lua
local Lx_UI = _G.Lx_UI
local gui = Lx_UI.register("My Tool", 420, 300, "my_tool")
gui:set_render_callback(function()
    -- draw your content here
end)
gui:toggle() -- open/close
```

Constraints
- Lua 5.1, no `os.*`, `io.*`, `print`, `error()`; use `core.*`.
- Use valid require paths.




