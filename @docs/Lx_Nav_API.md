Lx_Nav API

Global
- `_G.Lx_Nav.init()` → returns a table with:
  - `set_show_path(boolean)`
  - `set_debuglog(boolean)`
  - `set_use_look_at(boolean)` – enable/disable facing via `core.input.look_at`. Disabled by default; when off, steering uses key turns so you can see keyboard movement.
  - `move_to(vec3 pos, boolean direct, function onfinish)`
  - `get_path([vec3 start_pos], vec3 end_pos)`
  - `stop()` – immediately stops movement and releases steering inputs. Calls `onfinish(false)` if an in-flight move was stopped.


