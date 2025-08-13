### Lx_UI — TODOs & Milestones

Milestone 1: Scaffold & Parity
- [ ] Create `scripts/Lx_UI/` with `header.lua`, `main.lua`, `gui/` submodules.
- [ ] Export public API (`_G.Lx_UI` or local module; decide exposure policy).
- [ ] Implement base Menu class with parity components (render stubs ok initially).
- [ ] Hook update/render/menu callbacks; minimal render loop.
- [ ] Docs: `@docs/Lx_UI.md` and `@docs/Lx_UI_API.md`; update `@docs/INDEX.md`.

Milestone 2: Geometry & Windowing
- [ ] Add per-GUI geometry (x/y/w/h), persisted in save file.
- [ ] Implement dragging, z-order, edge snap; optional resize toggle.
- [ ] Input blocking: integrate hover/focus/listen checks.
- [ ] Migration helpers for position defaults.

Milestone 3: Quick-open Palette
- [ ] Add overlay with list of GUIs; fuzzy search; open/close behavior.
- [ ] Keybind to toggle; persistence for last selection.
- [ ] Input capture while active; dismiss rules (ESC/click outside).

Milestone 4: Optional Sidebar
- [ ] Collapsible icon bar; per-GUI visibility; reorder; pin.
- [ ] Settings to choose launcher mode (palette/sidebar/topbar).

Milestone 5: Polish
- [ ] Theming hooks; minimal config GUI.
- [ ] Performance passes and throttling helpers.
- [ ] Examples under `scripts/LX_UI_Example/`.
- [ ] Finalize docs and migration notes.

Notes
- Keep edits small; commit frequently.
- Respect Lua 5.1 sandbox and require-path rules.

- Docs
  - Update `@docs/Lx_UI.md` to clarify Designer inline rename: arrow keys move caret/selection (no character insertion).
  - Document double-click-to-edit behavior: double-click selects full text for quick overwrite.
  - Note: In inline edit, double-click inside input also selects all; ESC exits edit mode to allow moving components.


