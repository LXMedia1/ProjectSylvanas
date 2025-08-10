local constants = require("lx_ui/gui/utils/constants")

local Menu = {}
Menu.__index = Menu

function Menu:new(name, width, height, unique_key)
    local screen = core.graphics.get_screen_size()
    local gui = setmetatable({
        name = name,
        width = width or 420,
        height = height or 300,
        x = math.floor((screen.x - (width or 420)) / 2),
        y = 60,
        is_open = false,
        unique_key = unique_key or ("lx_ui_" .. name:lower():gsub("%s+","_")),
        render_callback = nil,
        _text_inputs = {},
        _keybinds = {}
    }, Menu)

    constants.registered_guis[name] = gui
    return gui
end

function Menu:set_render_callback(cb)
    self.render_callback = cb
end

function Menu:toggle()
    self.is_open = not self.is_open
end

return {
    Menu = Menu
}


