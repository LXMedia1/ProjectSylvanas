### Lx_UI — Plan Overview

Objective: Rebuild the GUI system as `Lx_UI` with a modern, flexible UX while retaining sandbox and persistence constraints from the old system.

Guiding principles
- Minimal changes per step; keep working at all times.
- Lua 5.1 only; no `os.*`, `io.*`, `print`, `error()`; use `core.*` APIs.
- Clean require paths; no dotted names; project-local imports only.
- No mock/fake data; rely on runtime `scripts/.api`.

High-level goals
- Floating draggable windows (default), snap to edges, z-order, geometry persistence.
- Quick-open palette (keybind) to launch GUIs without permanent chrome.
- Optional sidebar (icons) as alternative to legacy topbar.
- Per-GUI persistence (component values + geometry) using existing `core.*` file APIs.
- Strict input blocking rules (hover/focus/listen), compatible with existing behavior.

Phased approach
1) Foundation
   - Create `scripts/Lx_UI` with `header.lua`, `main.lua`, and `gui/` modules.
   - Port minimal Menu API parity (labels, buttons, checkbox, sliders, combo, keybind, text input) with geometry fields.
2) Geometry + Drag/Resize
   - Add drag, optional resize, edge snapping, z-order; persist x/y/w/h per GUI.
3) Quick-open palette
   - Overlay search/launcher with fuzzy filter; toggle via keybind.
4) Optional sidebar
   - Collapsible icon bar; per-GUI enable; reorder; pin.
5) Polishing
   - Docs, tests, examples, compatibility helpers, migration notes.

Compatibility
- Keep `LxCommon`’s blocking model; export `Lx_UI.isInputBlocked()`.
- Optionally offer a thin legacy shim if needed.

Docs
- Maintain `@docs` updates; provide friendly, structured docs with an index.


