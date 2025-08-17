# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Project Sylvanas is a Lua 5.1 modular framework for navigation, UI, and combat routines. The project uses a plugin-based architecture with modules that integrate with a host environment via `scripts/.api`.

## Architecture

### Core Modules
- **Lx_Nav** (`scripts/Lx_Nav/`): Pathfinding and navigation library with multi-tile mesh support
  - Uses binary `.mmap` and `.mmtile` files for navigation mesh data
  - Exposes API via `_G.Lx_Nav`
  - Key components: `tile_manager.lua`, `mmap_decode.lua`, `mesh_helper.lua`

- **Lx_UI** (`scripts/Lx_UI/`): Modern GUI system with floating windows and persistence
  - Implements draggable windows, input handling, and state persistence
  - GUI elements in `gui/elements/`, components in `gui/components/`
  - Designer/editor functionality in `gui/editor/`

- **Lx_Routine** (`scripts/Lx_Routine/`): Adaptive PvE combat routine system
  - Class-specific spell definitions in `spell_db/`
  - Core logic: `controller.lua`, `targeting.lua`, `healing.lua`, `prediction.lua`

### Module Structure
Each module follows this pattern:
- `header.lua`: Plugin metadata and load validation
- `main.lua`: Core initialization and API exposure
- Submodules use local requires (no dotted paths)

## Development Constraints

### Language & Runtime
- **Lua 5.1 only** - No 5.2+ features
- **Sandboxed environment** - No access to `os.*`, `io.*`, or `print`
- Use `core.*` APIs for all system interactions
- Error handling via `core.log_*` functions, not `error()`

### Import Rules
- Clean require paths without dots (e.g., `require('common/geometry/vector_3')`)
- Project-local imports only
- Modules expose APIs on `_G` (e.g., `_G.Lx_Nav`, `_G.Lx_UI`)

### Data Persistence
- Use `core.read_data_file()` and `core.write_data_file()` for persistence
- Data files stored in `scripts_data/` directory
- Configuration files use simple table serialization

## Common Development Tasks

### Running/Testing Modules
Since this is a plugin-based system that runs in a host environment:
- Modules are loaded by the host when `plugin["load"] = true` in header.lua
- Test functionality through the exposed global APIs
- Use `core.log_*` functions for debugging output

### Adding New Features
1. Follow existing module patterns (header.lua + main.lua structure)
2. Maintain Lua 5.1 compatibility
3. Use core.* APIs for system interactions
4. Update documentation in `@docs/` directory

### Debugging
- Enable debug logging via module APIs (e.g., `Lx_Nav.set_debuglog(true)`)
- Check `scripts_log/` directory for log files
- Use `core.log_info()`, `core.log_warning()`, `core.log_error()` for logging

## Key Implementation Details

### Lx_Nav Navigation System
- Implements A* pathfinding on navigation meshes
- Uses quantized coordinates (0.35m grid) for tile boundary alignment
- Supports multi-tile loading with automatic tile management
- Path smoothing with human-like movement patterns

### Lx_UI Window Management
- Floating draggable windows with z-order management
- Three launcher modes: Palette (quick-open), Sidebar (icons), Topbar (legacy)
- Geometry and state persistence via `scripts_data/Lx_UI/` 
- Input blocking system for proper focus management

### Lx_Routine Combat Logic
- Context-based spell prioritization
- Supports healing, DPS, and tank roles
- Extensible spell database system
- Predictive targeting and movement integration

## Documentation

Main documentation is in `@docs/`:
- `INDEX.md` - Documentation index
- `Lx_Nav.md`, `Lx_Nav_API.md` - Navigation documentation
- `Lx_UI.md`, `Lx_UI_API.md` - UI system documentation  
- `Lx_Routine.md`, `Lx_Routine_API.md` - Combat routine documentation

Planning documents in `@plan/`:
- `PLAN.md` - High-level architecture plans
- `TODOS.md` - Current development tasks
- `FEATURES.md` - Feature specifications