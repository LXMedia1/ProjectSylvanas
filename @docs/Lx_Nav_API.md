Lx_Nav API

Global
- `_G.Lx_Nav.init()` → returns a table with:
  - `set_show_path(boolean)`
  - `set_debuglog(boolean)`
  - `set_use_look_at(boolean)` – enable/disable facing via `core.input.look_at`. Disabled by default; when off, steering uses key turns so you can see keyboard movement.
  - Performance defaults:
    - Internally, tiles are loaded within `tile_load_radius = 1` and evicted beyond `tile_keep_radius = 2`.
    - The path overlay draws even if general visualization is disabled; use `set_show_path(true)` to display it.
  - `move_to(vec3 pos, boolean direct, function onfinish)`
  - `get_path([vec3 start_pos], vec3 end_pos)`
  - `stop()` – immediately stops movement and releases steering inputs. Calls `onfinish(false)` if an in-flight move was stopped.


