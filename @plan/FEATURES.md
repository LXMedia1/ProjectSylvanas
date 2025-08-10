### Lx_UI — Feature List (Initial Scope)

Core
- Floating windows: draggable, optional resize, edge snap, persisted geometry (x/y/w/h).
- Z-order management: click-to-front, simple stacking.
- Input blocking: hover/focus/listen states; exported helper.
- Persistence: per-GUI file using `core.create_data_file`, `core.write_data_file`, `core.read_data_file`.

Components (parity-first)
- Labels, Buttons, Checkboxes, Sliders (int/float), Comboboxes, Keybinds (with visibility/toggle), Text Inputs, Color Pickers, Headers, Tree Nodes, Listboxes, Images.

Launchers
- Quick-open palette: overlay with search; keybind to open; fuzzy filter.
- Optional Sidebar: icons to open GUIs; pin/unpin; reorder; toggle in settings.
- Legacy Topbar setting: optional for backward familiarity.

Quality
- Theming hooks (colors/fonts); minimal default dark theme.
- Performance-friendly dynamic updates (throttle helpers).
- Safe error/logging paths via `core.log`, `core.log_warning`, `core.log_error`.

Out of scope (phase 1)
- Complex docking layouts; multi-monitor persistence; advanced animations.


