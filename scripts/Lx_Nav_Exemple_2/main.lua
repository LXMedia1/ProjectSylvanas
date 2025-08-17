-- Lx_Nav_Exemple_2: Menu-driven showcase for _G.Lx_Nav_2

local vec3 = require('common/geometry/vector_3')

-- Initialize the shared navigation API
local Nav2 = _G.Lx_Nav_2 and _G.Lx_Nav_2.init()
if not Nav2 then
  core.log_error("Lx_Nav_Exemple_2: _G.Lx_Nav_2 not available. Ensure Lx_Nav_2 is enabled and loads first.")
  return
end

-- Example state
local ui = {
  menu_tree = nil,
  cb_debug = nil,
  cb_show_path = nil,
  cb_debuglog = nil,
  cb_use_look_at = nil,
  cb_layer_view = nil,
  cb_path_polys = nil,
  cb_smoothing = nil,
  btn_save = nil,
  btn_path = nil,
  btn_move = nil,
  btn_stop = nil,
  btn_clear = nil,
  btn_rebuild = nil,
  btn_next_method = nil,
  btn_alt_paths = nil,
  btn_load_build = nil,
}

local saved_position = nil

core.register_on_render_menu_callback(function()
  if not ui.menu_tree then
    ui.menu_tree = core.menu.tree_node()
    ui.cb_debug = core.menu.checkbox(false, "lx_nav2_example_debug")
    ui.cb_show_path = core.menu.checkbox(false, "lx_nav2_example_show_path")
    ui.cb_debuglog = core.menu.checkbox(false, "lx_nav2_example_debuglog")
    -- Fine-grained debug toggles
    ui.debug_tree = core.menu.tree_node()
    ui.cb_dbg_extraction = core.menu.checkbox(false, "lx_nav2_dbg_extraction")
    ui.cb_dbg_merge = core.menu.checkbox(false, "lx_nav2_dbg_merge")
    ui.cb_dbg_graph = core.menu.checkbox(false, "lx_nav2_dbg_graph")
    ui.cb_dbg_tiles = core.menu.checkbox(false, "lx_nav2_dbg_tiles")
    ui.cb_dbg_eviction = core.menu.checkbox(false, "lx_nav2_dbg_eviction")
    ui.cb_dbg_timing = core.menu.checkbox(false, "lx_nav2_dbg_timing")
    ui.cb_use_look_at = core.menu.checkbox(false, "lx_nav2_example_use_look_at")
    ui.cb_layer_view = core.menu.checkbox(false, "lx_nav2_example_corridor_layers")
    ui.cb_path_polys = core.menu.checkbox(false, "lx_nav2_example_draw_path_polys")
    ui.cb_smoothing = core.menu.checkbox(true, "lx_nav2_example_smoothing")
    ui.btn_save = core.menu.button("lx_nav2_example_save")
    ui.btn_path = core.menu.button("lx_nav2_example_path")
    ui.btn_move = core.menu.button("lx_nav2_example_move")
    ui.btn_stop = core.menu.button("lx_nav2_example_stop")
    ui.btn_clear = core.menu.button("lx_nav2_example_clear")
    ui.btn_rebuild = core.menu.button("lx_nav2_example_rebuild")
    ui.btn_next_method = core.menu.button("lx_nav2_example_next_method")
    ui.btn_alt_paths = core.menu.button("lx_nav2_example_alt_paths")
    ui.btn_load_build = core.menu.button("lx_nav2_example_load_build")
  end

  ui.menu_tree:render("Lx_Nav_2 Example", function()
    -- Toggles
    ui.cb_debug:render("Debug mode")
    Nav2.set_debug(ui.cb_debug:get_state())

    ui.cb_show_path:render("Show path")
    Nav2.set_show_path(ui.cb_show_path:get_state())

    ui.cb_debuglog:render("Debug log")
    Nav2.set_debuglog(ui.cb_debuglog:get_state())

    ui.cb_use_look_at:render("Use look_at steering")
    Nav2.set_use_look_at(ui.cb_use_look_at:get_state())

    ui.cb_layer_view:render("Corridor layers (no path)")
    Nav2.set_draw_corridor_layers(ui.cb_layer_view:get_state())

    ui.cb_path_polys:render("Draw path polys")
    Nav2.set_draw_path_polys(ui.cb_path_polys:get_state())

    ui.cb_smoothing:render("Enable smoothing")
    Nav2.set_smoothing(ui.cb_smoothing:get_state())

    -- Fine-grained debug controls
    ui.debug_tree:render("Debug Details", function()
      ui.cb_dbg_extraction:render("Extractor debug")
      Nav2.set_debug_extraction(ui.cb_dbg_extraction:get_state())

      ui.cb_dbg_merge:render("Merge debug")
      Nav2.set_debug_merge(ui.cb_dbg_merge:get_state())

      ui.cb_dbg_graph:render("Graph debug")
      Nav2.set_debug_graph(ui.cb_dbg_graph:get_state())

      ui.cb_dbg_tiles:render("Tile load debug")
      Nav2.set_debug_tiles(ui.cb_dbg_tiles:get_state())

      ui.cb_dbg_eviction:render("Tile eviction debug")
      Nav2.set_debug_eviction(ui.cb_dbg_eviction:get_state())

      ui.cb_dbg_timing:render("Timing (cpu_ticks) debug")
      Nav2.set_debug_timing(ui.cb_dbg_timing:get_state())
    end)

    -- Actions
    ui.btn_save:render("Save target (player pos)")
    if ui.btn_save:is_clicked() then
      core.log("[Nav2 Example][BTN] Save target clicked")
      local player = core.object_manager.get_local_player()
      if player then
        saved_position = player:get_position()
        core.log("[Nav2 Example] Saved target (player position)")
      end
    end

    ui.btn_path:render("Compute path to saved")
    if ui.btn_path:is_clicked() then
      core.log("[Nav2 Example][BTN] Compute path clicked")
      if not Nav2.is_graph_ready() then
        local progress = Nav2.get_graph_progress() or 0
        core.log_warning("[Nav2 Example] Graph not ready (" .. tostring(math.floor(progress * 100)) .. "%). Try again in a moment.")
      else
        if not saved_position then
          core.log_warning("[Nav2 Example] No saved target yet")
        else
          local player = core.object_manager.get_local_player()
          if player then
            local path = Nav2.get_path(player:get_position(), saved_position)
            if not path or #path < 2 then
              core.log_warning("[Nav2 Example] No path computed")
            else
              core.log("[Nav2 Example] Path nodes: " .. tostring(#path))
              if ui.cb_show_path and ui.cb_show_path:get_state() then
                Nav2.draw_path(path)
              end
            end
          end
        end
      end
    end

    ui.btn_move:render("Move to saved")
    if ui.btn_move:is_clicked() then
      core.log("[Nav2 Example][BTN] Move clicked")
      if not saved_position then
        core.log_warning("[Nav2 Example] No saved target yet")
      else
        Nav2.move_to(saved_position, false, function(ok)
          if ok then
            core.log("[Nav2 Example] Destination reached")
          else
            core.log_warning("[Nav2 Example] Movement finished (not reached)")
          end
        end)
      end
    end

    ui.btn_stop:render("Stop movement")
    if ui.btn_stop:is_clicked() then
      core.log("[Nav2 Example][BTN] Stop clicked")
      Nav2.stop()
      core.log("[Nav2 Example] Stop requested")
    end

    ui.btn_clear:render("Clear navigation data")
    if ui.btn_clear:is_clicked() then
      core.log("[Nav2 Example][BTN] Clear clicked")
      Nav2.clear()
      core.log("[Nav2 Example] Cleared navigation data")
    end

    ui.btn_rebuild:render("Rebuild graph")
    if ui.btn_rebuild:is_clicked() then
      core.log("[Nav2 Example][BTN] Rebuild graph clicked")
      Nav2.rebuild_graph()
      core.log("[Nav2 Example] Graph rebuild requested")
    end

    ui.btn_load_build:render("Load tiles + Build graph")
    if ui.btn_load_build:is_clicked() then
      core.log("[Nav2 Example][BTN] Load tiles + Build graph clicked")
      local loaded = Nav2.ensure_tiles_and_build(2)
      core.log("[Nav2 Example] Loaded tiles: " .. tostring(loaded))
    end

    -- Advanced demos
    ui.btn_next_method:render("Next smoothing method")
    if ui.btn_next_method:is_clicked() then
      core.log("[Nav2 Example][BTN] Next smoothing method clicked")
      local methods = Nav2.get_smoothing_methods()
      local order = {}
      for _, name in pairs(methods) do table.insert(order, name) end
      table.sort(order)
      local current_method = Nav2.get_smoothing_method() or order[1]
      local idx = 1
      for i = 1, #order do if order[i] == current_method then idx = i break end end
      local next_idx = (idx % #order) + 1
      Nav2.set_smoothing_method(order[next_idx])
      core.log("[Nav2 Example] Smoothing method -> " .. tostring(order[next_idx]))
    end

    ui.btn_alt_paths:render("Find alternative paths")
    if ui.btn_alt_paths:is_clicked() then
      core.log("[Nav2 Example][BTN] Find alternative paths clicked")
      if not saved_position then
        core.log_warning("[Nav2 Example] No saved target yet")
      else
        local player = core.object_manager.get_local_player()
        if player then
          local paths = Nav2.find_alternative_paths(saved_position, 3)
          core.log("[Nav2 Example] Alt paths found: " .. tostring(paths and #paths or 0))
        end
      end
    end
  end)
end)


