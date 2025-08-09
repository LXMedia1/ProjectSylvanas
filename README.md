## Project Sylvanas

Lua 5.1 modules and tooling for navigation and movement. This repository focuses on a clean, minimal API surface that integrates with a host environment via `scripts/.api` (no `os.*`, `io.*`, or `print`).

### Key module
- **Lx_Nav**: Standalone navigation library with pathfinding and human‑like movement
  - Setup & Usage: [@docs/Lx_Nav.md](@docs/Lx_Nav.md)

### Docs
- All documentation lives in `@docs/`
  - Index (work in progress): `@docs/INDEX.md`

### Notes
- Target runtime: Lua 5.1
- Library only: no built‑in UI or menus; drawing/logging are off by default
