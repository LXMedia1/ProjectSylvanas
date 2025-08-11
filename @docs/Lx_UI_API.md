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
- `gui:AddLabel(text, x, y, [color], [font_size])`
- `gui:AddTabs(items[, y_offset]) -> tabs`
- `gui:AddButton(text, x, y, w, h, [on_click]) -> button`
- `gui:AddCheckbox(label, x, y, [checked], [on_change]) -> checkbox`
- `gui:AddPanel(title, x, y, w, h) -> panel`
- `gui:AddListbox(x, y, w, h, items[, on_change]) -> listbox`
- Fields: `gui.name`, `gui.x`, `gui.y`, `gui.width`, `gui.height`, `gui.is_open`.

Notes
- Geometry persistence and drag/resize will be added per plan.

Label
- Adds a static text label relative to the window's top-left corner.
- Example: `gui:AddLabel("Hello World", 10, 10)`
- Optional parameters:
  - `color` defaults to `constants.color.white(255)`
  - `font_size` defaults to `constants.FONT_SIZE`

Tabs
- Horizontal tab bar under the window header.
- Create: `local tabs = gui:AddTabs({ {id="Active", label="Active"}, {id="Settings", label="Settings"}, {id="Editor", label="Editor"} })`
- Check active: `tabs:is_active("Active")`
- Set active: `tabs:set_active("Editor")`

Button
- Adds a clickable button.
- Create: `gui:AddButton("Apply", 16, 220, 120, 28, function(btn) ... end)`

Checkbox
- Adds a labeled checkbox.
- Create: `local cb = gui:AddCheckbox("Enable feature", 16, 260, true, function(self, value) ... end)`
- Accessors: `cb:get()`, `cb:set(true|false)`, `cb:toggle()`, `cb:set_on_change(fn)`

Panel
- Draws a framed container with a title and header.
- Create: `local p = gui:AddPanel("Loaded Windows", 16, 120, 360, 200)`
- Helpers: `p:set_visible_if(fn)`, `p:get_content_origin()`, `p:get_content_size()`

Listbox
- Scroll-less list selection control.
- Create: `local lb = gui:AddListbox(16, 120, 180, 140, {"Item A", "Item B"}, function(self, idx, text) ... end)`
- Methods: `lb:set_items(tbl)`, `lb:get_selected_index()`, `lb:get_selected_text()`, `lb:set_selected_index(i)`, `lb:set_visible_if(fn)`




