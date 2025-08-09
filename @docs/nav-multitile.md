Multi-tile Pathfinding

Overview
- The navigator now loads a 3x3 neighborhood of tiles around the player and merges polygons across tiles for pathfinding.
- Polygons are connected across tile borders by matching quantized world edge coordinates.

How it works
- Tile loading: `TileManager:ensure_neighbor_tiles_loaded(cx, cy, radius)` pulls tiles from `mmaps/` via `core.read_data_file` and parses them with `MMap.parse_tile`.
- Merge graph: `TileManager:rebuild_merged_graph()` concatenates polygons from `self.tiles` and builds a graph via `TileManager:build_graph`.
- Cross-tile edges: edges are keyed using 10cm-quantized XY world coordinates so adjacent tiles share edges.
- Path building: `compute_path_to_saved()` makes sure start/goal neighborhoods are loaded, then runs A* and builds a corridor using portal midpoints.
 - Edge padding: portal midpoints are nudged towards the next polygon center by `safety_margin` meters to keep the path away from walls/edges. Tune via the menu slider.

Usage
- Save a destination using the menu, then click "Path to saved".
- The system will recompute as you move; it transparently crosses tile borders.

Limitations / TODO
- Only a 3x3 neighborhood is auto-loaded; very long paths might need progressive loading while following.
- Off-mesh links are not yet stitched across tiles.
- Path hugs edges in very narrow corridors. Consider adaptive margin based on local portal width.
- Debug polygon fill for the center tile still uses `self.current_tile_data`; cross-tile debug fill is limited to path highlights.

