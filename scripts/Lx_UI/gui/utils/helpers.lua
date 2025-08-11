local constants = require("gui/utils/constants")

local function is_point_in_rect(px, py, x, y, w, h)
    return px >= x and px <= x + w and py >= y and py <= y + h
end

local function is_mouse_over_gui_area()
    local pos = constants.mouse_state.position
    -- Include topbar area when topbar launcher is active
    if (constants.launcher_mode or 1) == 3 and core.graphics and core.graphics.get_screen_size then
        local screen = core.graphics.get_screen_size()
        if is_point_in_rect(pos.x, pos.y, 0, 0, screen.x, 28) then
            return true
        end
    end
    -- Include palette panel when palette is active
    if (constants.launcher_mode or 1) == 1 then
        local r = constants.palette_rect
        if r and is_point_in_rect(pos.x, pos.y, r.x, r.y, r.w, r.h) then
            return true
        end
    end
    -- Include sidebar area when sidebar launcher is active
    if (constants.launcher_mode or 1) == 2 then
        local x = 8
        local w = constants.SIDEBAR_WIDTH or 160
        local y0 = (constants.SIDEBAR_TOP_OFFSET or 80) - 8
        local h = (core.graphics and core.graphics.get_screen_size and core.graphics.get_screen_size().y or 800)
        if is_point_in_rect(pos.x, pos.y, x - 6, y0, w + 12, h) then
            return true
        end
    end
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




