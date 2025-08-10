### Lx_UI — Public API

Globals
- `_G.Lx_UI` table is exported for convenience.

Exports
- `Lx_UI.register(name, width, height, unique_key) -> gui`
- `Lx_UI.Menu` class
- `Lx_UI.isInputBlocked() -> boolean`

GUI methods
- `gui:set_render_callback(function)`
- `gui:toggle()`
- Fields: `gui.name`, `gui.x`, `gui.y`, `gui.width`, `gui.height`, `gui.is_open`.

Notes
- Geometry persistence and drag/resize will be added per plan.


