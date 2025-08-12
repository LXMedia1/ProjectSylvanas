### Lx_Nav — Release Notes

#### Version 1.0
- Initial public release.

#### Version 1.1
- Path drawing no longer depends on debug visualization; controlled solely by `set_show_path(true/false)`.
- Auto-hide path when destination is reached (clears `path_nodes` and `path_poly_ids`).
- Added distance-based tile eviction to prevent memory bloat over time:
  - New internal setting `tile_keep_radius` (default: 2) used in `evict_far_tiles`.
  - Eviction triggers a graph rebuild from remaining tiles.
- Added debug log for tile eviction when `debuglog_enabled` is true, e.g.:
  - `[Nav] Evicting 3 tile(s) beyond r=2 from center 34:27 (e.g. 31:24,31:25,31:26)`
- Docs updated to reflect the above behaviors.


