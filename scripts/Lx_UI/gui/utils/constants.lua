-- ==================== CONSTANTS ====================

local color = require("common/color")
local vec2 = require("common/geometry/vector_2")

local Settings = {
    debug_mode = false
}

local registered_guis = {}
local gui_states = {}

local mouse_state = {
    position = vec2.new(0, 0),
    left_down = false,
    left_clicked = false,
    last_left = false,
    is_over_gui = false,
}

return {
    color = color,
    vec2 = vec2,
    Settings = Settings,
    registered_guis = registered_guis,
    gui_states = gui_states,
    mouse_state = mouse_state,
    launcher_mode = 1 -- 1=palette, 2=sidebar, 3=topbar
}


