local vec3 = require('common/geometry/vector_3')
local color = require('common/color')

-- Initialize the shared navigation API
local Nav = _G.Lx_Nav and _G.Lx_Nav.init()
if not Nav then
  core.log_error("Lx_Nav_Exemple: _G.Lx_Nav not available. Ensure Lx_Nav is enabled and loads first.")
  return
end

-- Example state
local ui = {
  menu_tree = nil,
  cb_show_path = nil,
  cb_debuglog = nil,
  cb_use_look_at = nil,
  btn_save = nil,
  btn_path = nil,
  btn_move = nil,
    btn_stop = nil,
}

local saved_position = nil

core.register_on_render_menu_callback(function()
  if not ui.menu_tree then
    ui.menu_tree = core.menu.tree_node()
    ui.cb_show_path = core.menu.checkbox(false, "lx_nav_example_show_path")
    ui.cb_debuglog = core.menu.checkbox(false, "lx_nav_example_debuglog")
    ui.cb_use_look_at = core.menu.checkbox(false, "lx_nav_example_use_look_at")
    ui.cb_layer_view = core.menu.checkbox(false, "lx_nav_example_corridor_layers")
    ui.cb_path_polys = core.menu.checkbox(false, "lx_nav_example_draw_path_polys")
    ui.btn_save = core.menu.button("lx_nav_example_save")
    ui.btn_path = core.menu.button("lx_nav_example_path")
    ui.btn_move = core.menu.button("lx_nav_example_move")
    ui.btn_stop = core.menu.button("lx_nav_example_stop")
  end

  ui.menu_tree:render("Lx_Nav Example", function()
    ui.cb_show_path:render("Show path")
    Nav.set_show_path(ui.cb_show_path:get_state())

    ui.cb_debuglog:render("Debug log")
    Nav.set_debuglog(ui.cb_debuglog:get_state())

    ui.cb_use_look_at:render("Use look_at steering (toggle)")
    Nav.set_use_look_at(ui.cb_use_look_at:get_state())

    ui.cb_layer_view:render("Corridor layers (no path)")
    Nav.set_draw_corridor_layers(ui.cb_layer_view:get_state())

    ui.cb_path_polys:render("Draw path polys")
    Nav.set_draw_path_polys(ui.cb_path_polys:get_state())

    ui.btn_save:render("Save target")
    if ui.btn_save:is_clicked() then
      local player = core.object_manager.get_local_player()
      if player then
        saved_position = player:get_position()
        core.log("[Example] Saved target (player position)")
      end
    end

    ui.btn_path:render("Compute path to saved")
    if ui.btn_path:is_clicked() then
      if not saved_position then
        core.log_warning("[Example] No saved target yet")
      else
        local player = core.object_manager.get_local_player()
        if player then
          local path = Nav.get_path(player:get_position(), saved_position)
          if not path or #path < 2 then
            core.log_warning("[Example] No path computed")
          else
            core.log("[Example] Path nodes: " .. tostring(#path))
          end
        end
      end
    end

    ui.btn_move:render("Move to saved")
    if ui.btn_move:is_clicked() then
      if not saved_position then
        core.log_warning("[Example] No saved target yet")
      else
        Nav.move_to(saved_position, false, function(ok)
          if ok then
            core.log("[Example] Destination reached")
          else
            core.log_warning("[Example] Movement finished (not reached)")
          end
        end)
      end
    end

    ui.btn_stop:render("Stop movement")
    if ui.btn_stop:is_clicked() then
      Nav.stop()
      core.log("[Example] Stop requested")
    end
  end)
end)


