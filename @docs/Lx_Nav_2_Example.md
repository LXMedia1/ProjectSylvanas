### Lx_Nav_2 Example Plugin

This example plugin (`scripts/Lx_Nav_Exemple_2`) showcases the `_G.Lx_Nav_2` API with a simple menu.

Features exposed:
- Debug toggles: debug mode, log enable
- Rendering toggles: show path, corridor layers, path polygons
- Movement options: use look_at steering, smoothing enable
- Actions: save target (player pos), compute path, move to target, stop, clear data, rebuild graph

Usage:
1. Enable `Lx_Nav_2` plugin.
2. Enable `Lx_Nav_Exemple_2` plugin.
3. Open the in-game menu and expand "Lx_Nav_2 Example".
4. Click "Save target" to store current player position, then "Compute path" or "Move to saved".

Notes:
- Requires a valid local player.
- Uses only Lua 5.1 and `scripts/.api` calls per project rules.


