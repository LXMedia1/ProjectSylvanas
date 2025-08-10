local constants = require("Lx_UI/gui/utils/constants")
local input = require("Lx_UI/gui/functions/input")

local function render_window(gui)
    -- background
    local bg = constants.color.new(20, 20, 30, 220)
    core.graphics.rect_filled(gui.x, gui.y, gui.width, gui.height, bg)
    -- header bar
    local hb = constants.color.new(40, 60, 100, 240)
    core.graphics.rect_filled(gui.x, gui.y, gui.width, 24, hb)
    core.graphics.text(gui.name or "Window", gui.x + 8, gui.y + 5, constants.color.white(255))
    -- user content
    if gui.render_callback then gui:render_callback() end
end

local function render_all()
    input.update_mouse()
    for _, gui in pairs(constants.registered_guis) do
        if gui.is_open then render_window(gui) end
    end
end

local function render_menu_controls()
    -- Reserved for settings; minimal for now
end

return {
    render_all = render_all,
    render_menu_controls = render_menu_controls
}




