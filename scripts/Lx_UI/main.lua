-- ==================== Lx_UI MAIN ====================

-- Imports (module-local, no globals exposed yet)
local constants = require("Lx_UI/gui/utils/constants")
local helpers = require("Lx_UI/gui/utils/helpers")
local input = require("Lx_UI/gui/functions/input")
local rendering = require("Lx_UI/gui/functions/rendering")
local menu_module = require("Lx_UI/gui/elements/menu")

local Menu = menu_module.Menu

-- Settings entry in main menu
local ui_tree = core.menu.tree_node()
local launcher_mode_combo = core.menu.combobox(1, "lx_ui_launcher_mode") -- 1=palette, 2=sidebar, 3=topbar

-- Update loop
local function on_update()
    -- Keep launcher mode in constants
    constants.launcher_mode = launcher_mode_combo and launcher_mode_combo:get_state() or 1
end

-- Render loop
local function on_render()
    rendering.render_all()
end

-- Menu rendering
local function on_render_menu()
    ui_tree:render("Lx_UI", function()
        if launcher_mode_combo then
            launcher_mode_combo:render("Launcher Mode", "1=Palette, 2=Sidebar, 3=Topbar (legacy)")
        end
        rendering.render_menu_controls()
    end)
end

-- Public API (avoid global unless needed; keep a module table)
local Lx_UI = {
    Menu = Menu,
    register = function(name, width, height, unique_key)
        return Menu:new(name, width, height, unique_key)
    end,
    isInputBlocked = function()
        return helpers.is_input_blocked()
    end
}

-- Optionally expose globally if required by other libs
_G.Lx_UI = Lx_UI

-- Register callbacks
core.register_on_update_callback(on_update)
core.register_on_render_callback(on_render)
core.register_on_render_menu_callback(on_render_menu)

core.log("Lx_UI loaded: modular UI system initialized")

return Lx_UI




