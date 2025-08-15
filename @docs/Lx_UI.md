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

### Color Picker

The built-in `ColorPicker` component supports multiple closed-button styles. Set via `opts.style` when creating the picker or via the Designer property.

- Styles: `"classic"`, `"split"`, `"pill"`, `"neon"`, `"glass"`
- Example:
```lua
local cp = gui:AddColorPicker(16, 60, 160, 24, { r=120, g=180, b=255, a=240 }, function(self, c)
    -- use c.r,c.g,c.b,c.a
end, { style = "neon", placeholder = "Accent" })
```

Notes
- `neon`: animated glow outline based on the current color.
- `glass`: translucent glassmorphism look with a soft highlight.

### Window

The `Window` component supports multiple draw styles. Configure via the Designer (Draw Style) or by setting `comp.style`.

- Styles: `"window"`, `"box"`, `"invisible"`, `"futuristic"`, `"clean"`, `"modern"`, `"flat"`, `"win95"`
- Example:
```lua
local win = gui:AddWindow("My Panel", 40, 40, 360, 220)
win.style = "win95" -- or "futuristic"/"clean"/"modern"/"flat"
```

Designer rules
- In the Designer, `Window` is the only root/base container. All components (including other containers like `Panel`, `ScrollArea`, `Optionbox`, `Spoiler`) must be placed inside a `Window`.
- Drag-and-drop onto the canvas enforces this; drops outside any `Window` are rejected with a hint.

