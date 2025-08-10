local constants = require("Lx_UI/gui/utils/constants")

local function is_point_in_rect(px, py, x, y, w, h)
    return px >= x and px <= x + w and py >= y and py <= y + h
end

local function is_mouse_over_gui_area()
    local pos = constants.mouse_state.position
    for _, gui in pairs(constants.registered_guis) do
        if gui.is_open then
            if is_point_in_rect(pos.x, pos.y, gui.x, gui.y, gui.width, gui.height) then
                return true
            end
        end
    end
    return false
end

local function is_input_blocked()
    if is_mouse_over_gui_area() then return true end
    for _, gui in pairs(constants.registered_guis) do
        if gui.is_open then
            if gui._text_inputs then
                for _, ti in ipairs(gui._text_inputs) do
                    if ti.is_focused then return true end
                end
            end
            if gui._keybinds then
                for _, kb in ipairs(gui._keybinds) do
                    if kb.is_listening then return true end
                end
            end
        end
    end
    return false
end

return {
    is_point_in_rect = is_point_in_rect,
    is_mouse_over_gui_area = is_mouse_over_gui_area,
    is_input_blocked = is_input_blocked
}




