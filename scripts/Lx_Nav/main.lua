---@type vec3
local vec3 = require('common/geometry/vector_3')
---@type vec2
local vec2 = require('common/geometry/vector_2')
---@type color
local color = require('common/color')

local TileManager = require('tile_manager')


-- Expose API on _G.Lx_Nav
_G.Lx_Nav = _G.Lx_Nav or {}

function _G.Lx_Nav.init()
  local tm = TileManager:new()
  tm:start()
  return {
    -- flags
    set_show_path = function(v) tm.show_path = not not v end,
    set_debuglog = function(v) tm.debuglog_enabled = not not v end,
    set_use_look_at = function(v) tm.use_look_at = not not v end,
    -- properties (shortcut style)
    __tm = tm,
    -- movement
    move_to = function(pos, direct, onfinish)
      if direct then
        -- Direct guidance movement without A*
        tm.path_nodes = { core.object_manager.get_local_player():get_position(), pos }
        tm.saved_position = pos
        tm.move_finish_cb = onfinish
        tm:start_move_to_saved()
      else
        tm.saved_position = pos
        tm:compute_path_to_saved()
        tm.move_finish_cb = onfinish
        tm:start_move_to_saved()
      end
    end,
    stop = function()
      tm:stop_movement()
    end,
    -- path queries
    get_path = function(start_pos, end_pos)
      if start_pos then
        -- temporarily compute from custom start
        local player = core.object_manager.get_local_player()
        local saved = tm.saved_position
        tm.saved_position = end_pos
        -- Fake player start by creating path from start_pos: temporarily override find_closest_node input
        -- Easiest: move player-based start reading by a local wrapper
        local path = tm:path_from_to(start_pos, end_pos)
        tm.saved_position = saved
        return path
      else
        return tm.path_nodes
      end
    end,
  }
end

