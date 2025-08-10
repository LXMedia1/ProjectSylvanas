local constants = require("lx_ui/gui/utils/constants")
local helpers = require("lx_ui/gui/utils/helpers")

local function update_mouse()
    local p = core.get_cursor_position()
    constants.mouse_state.position.x = p.x
    constants.mouse_state.position.y = p.y
    local down = core.input.is_key_pressed(0x01)
    constants.mouse_state.left_clicked = constants.mouse_state.last_left and not down
    constants.mouse_state.left_down = down
    constants.mouse_state.last_left = down
    constants.mouse_state.is_over_gui = helpers.is_mouse_over_gui_area()
end

return {
    update_mouse = update_mouse
}


