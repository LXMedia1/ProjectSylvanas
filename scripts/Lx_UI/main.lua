-- ==================== Lx_UI MAIN ====================

-- Imports (module-local, no globals exposed yet)
local constants = require("gui/utils/constants")
local helpers = require("gui/utils/helpers")
local persist = require("gui/utils/persist")
local input = require("gui/functions/input")
local rendering = require("gui/functions/rendering")
local menu_module = require("gui/elements/menu")

local Menu = menu_module.Menu

local ui_tree = core.menu and core.menu.tree_node and core.menu.tree_node() or nil
local settings_open_checkbox = (core.menu and core.menu.checkbox) and core.menu.checkbox(false, "lx_ui_settings_open") or nil
local settings_gui = nil
-- Launcher mode combobox (1=Palette, 2=Sidebar, 3=Topbar)
local launcher_mode_options = { "Palette", "Sidebar", "Topbar" }
local launcher_mode_combo = (core.menu and core.menu.combobox) and core.menu.combobox(1, "lx_ui_launcher_mode") or nil
local sidebar_offset_slider = nil
local palette_offset_slider = nil
local palette_left_slider = nil
local plugin_cfg_loaded = false

-- Update loop
local function on_update()
    -- Ensure data folders
    persist.ensure_dirs()
    -- Load plugin settings once
    if not plugin_cfg_loaded then
        local cfg = persist.load_plugin() or {}
        if tonumber(cfg.launcher_mode) then constants.launcher_mode = tonumber(cfg.launcher_mode) end
        if tonumber(cfg.sidebar_top_offset) then constants.SIDEBAR_TOP_OFFSET = tonumber(cfg.sidebar_top_offset) end
        if tonumber(cfg.palette_top_offset) then constants.PALETTE_TOP_OFFSET = tonumber(cfg.palette_top_offset) end
        if tonumber(cfg.palette_left_offset) then constants.PALETTE_LEFT_OFFSET = tonumber(cfg.palette_left_offset) end
        -- Reflect combobox if available
        if launcher_mode_combo and launcher_mode_combo.set then
            launcher_mode_combo:set(constants.launcher_mode or 1)
        end
        plugin_cfg_loaded = true
    end
    -- Ensure a copy of logo is present in scripts_data/ressource/logo.png for binary loading
    if core.read_file and core.create_data_folder and core.create_data_file and core.write_data_file and not _G.__lxui_logo_copied then
        local raw_paths = {
            "ressource/logo.png",
            "resources/logo.png",
            "Lx_UI/ressource/logo.png",
            "Lx_UI/resources/logo.png",
            "scripts/Lx_UI/ressource/logo.png",
            "scripts/Lx_UI/resources/logo.png"
        }
        local data = nil
        for i=1,#raw_paths do
            data = core.read_file(raw_paths[i])
            if data and #data > 0 then break end
        end
        if data and #data > 0 then
            core.create_data_folder("ressource")
            core.create_data_file("ressource/logo.png")
            core.write_data_file("ressource/logo.png", data)
            _G.__lxui_logo_copied = true
        end
    end
    -- Ensure settings GUI exists even if the menu was never opened
    if not settings_gui then
        settings_gui = Lx_UI.register("Lx_UI Settings", 1000, 800, "lx_ui_settings")
        settings_gui.is_hidden_from_launcher = true
        settings_gui.is_fixed = true
        settings_gui.is_settings = true
        settings_gui.width = 1000
        settings_gui.height = 800
        constants.gui_states[settings_gui.name] = nil
        -- Tabs for Settings window
        settings_gui._tabs = settings_gui:AddTabs({
            { id = "Active Windows", label = "Active Windows" },
            { id = "Settings", label = "Settings" },
            { id = "Editor", label = "Editor" }
        }, (constants.HEADER_HEIGHT or 24) + 6)
        -- Small hint label under the tabs (component demo)
        settings_gui._hint_label = settings_gui:AddLabel(
            "Use tabs to switch sections",
            16,
            (constants.HEADER_HEIGHT or 24) + 6 + 20 + 6,
            constants.color.new(220,220,230,220),
            12
        )
        settings_gui:set_render_callback(function(gui)
            local header_h = (constants.HEADER_HEIGHT or 24)
            local tabs_h = 20
            local local_hint_y = header_h + 6 + tabs_h + 6
            local base_y = local_hint_y + (constants.FONT_SIZE or 14) + 2 -- panel starts just below hint
            local x_text = 16
            local x_local = 16
            if core.graphics and core.graphics.text_2d then
                local col = constants.color.white(255)
                local soft = constants.color.new(220,220,230,220)
                if gui._tabs and gui._tabs.is_active and gui._tabs:is_active("Active Windows") then
                    -- Panel with per-window checkboxes
                    if not gui._loaded_panel then
                        -- Left-side, compact panel. We'll also update its position/size every frame.
                        gui._loaded_panel = gui:AddPanel("Loaded Windows", x_local, base_y, 320, 200)
                        gui._loaded_panel:set_visible_if(function()
                            return gui._tabs and gui._tabs:is_active("Active Windows")
                        end)
                    end
                    -- Keep position in sync if window moved
                    gui._loaded_panel.x = x_local
                    gui._loaded_panel.y = base_y
                    -- Lay out checkboxes inside the panel area (panel returns local coords)
                    local px, py = gui._loaded_panel:get_content_origin()
                    local cw, ch = gui._loaded_panel:get_content_size()
                    local cur_y = py
                    for name, g in pairs(constants.registered_guis) do
                        -- Create the checkbox once and then keep it
                        if name ~= "Lx_UI Settings" then
                            -- Read current launcher-enabled state from the menu checkbox (default true)
                            local enabled = true
                            local menu_chk = constants.gui_states[name]
                            if menu_chk then
                                if menu_chk.get_state then enabled = menu_chk:get_state()
                                elseif menu_chk.get then enabled = menu_chk:get() end
                            end
                            g.__loaded_checkbox = g.__loaded_checkbox or gui:AddCheckbox(name, px, cur_y, enabled, function(_, val)
                                -- Toggle visibility in launchers (Topbar/Sidebar/Palette) without opening the window
                                local m = constants.gui_states[name]
                                if m and m.set then m:set(val) end
                            end)
                            -- Only visible on the first tab
                            g.__loaded_checkbox:set_visible_if(function()
                                return gui._tabs and gui._tabs:is_active("Active Windows")
                            end)
                            -- Keep it positioned in case window size changes
                            g.__loaded_checkbox.x = px
                            g.__loaded_checkbox.y = cur_y
                            -- Keep in sync each frame with menu checkbox state
                            if menu_chk then
                                local cur_enabled = enabled
                                if menu_chk.get_state then cur_enabled = menu_chk:get_state() elseif menu_chk.get then cur_enabled = menu_chk:get() end
                                g.__loaded_checkbox:set(cur_enabled)
                            end
                            cur_y = cur_y + 22
                        end
                    end
                elseif gui._tabs and gui._tabs:is_active("Settings") then
                    local ox, oy = gui._tabs:get_content_origin()
                    local x = gui.x + ox
                    local y = gui.y + oy
                    -- Headline
                    core.graphics.text_2d("Settings:", constants.vec2.new(x, y), constants.FONT_SIZE, col, false)

                    -- Four listboxes: Default, Topbar, Sidebar, Palette
                    -- Build lists only once, then reuse
                    if not gui._lb_default then
                        gui._lb_default = gui:AddListbox(ox, oy + 20, 180, 200, {}, function() end, "Default"):setType("launcher"):setDropSlot("default")
                        gui._lb_topbar  = gui:AddListbox(ox + 190, oy + 20, 180, 200, {}, function() end, "Topbar"):setType("launcher"):setDropSlot("topbar")
                        gui._lb_sidebar = gui:AddListbox(ox + 380, oy + 20, 180, 200, {}, function() end, "Sidebar"):setType("launcher"):setDropSlot("sidebar")
                        gui._lb_palette = gui:AddListbox(ox + 570, oy + 20, 180, 200, {}, function() end, "Palette"):setType("launcher"):setDropSlot("palette")
                        gui._lb_default:set_visible_if(function() return gui._tabs:is_active("Settings") end)
                        gui._lb_topbar:set_visible_if(function() return gui._tabs:is_active("Settings") end)
                        gui._lb_sidebar:set_visible_if(function() return gui._tabs:is_active("Settings") end)
                        gui._lb_palette:set_visible_if(function() return gui._tabs:is_active("Settings") end)
                    end
                    -- Keep positions synced to tab origin
                    gui._lb_default.x, gui._lb_default.y = ox, oy + 20
                    gui._lb_topbar.x,  gui._lb_topbar.y  = ox + 190, oy + 20
                    gui._lb_sidebar.x, gui._lb_sidebar.y = ox + 380, oy + 20
                    gui._lb_palette.x, gui._lb_palette.y = ox + 570, oy + 20

                    -- Populate from current registered guis and assignments
                    local assigned = constants.launcher_assignments
                    local def, top, side, pal = {}, {}, {}, {}
                    for name, _ in pairs(constants.registered_guis) do
                        if name ~= "Lx_UI Settings" then
                            local slot = assigned[name] or "default"
                            if slot == "topbar" then table.insert(top, name)
                            elseif slot == "sidebar" then table.insert(side, name)
                            elseif slot == "palette" then table.insert(pal, name)
                            else table.insert(def, name) end
                        end
                    end
                    table.sort(def); table.sort(top); table.sort(side); table.sort(pal)
                    gui._lb_default:set_items(def)
                    gui._lb_topbar:set_items(top)
                    gui._lb_sidebar:set_items(side)
                    gui._lb_palette:set_items(pal)
                    -- Ensure GUI launcher filtering on-the-fly (renderers read constants.launcher_assignments)
                    -- After repopulating, nothing else to do; assignments already synced above when no drag is active
                else
                    -- Editor tab (placeholder)
                    local ox, oy = gui._tabs:get_content_origin()
                    local x = gui.x + ox
                    local y = gui.y + oy
                    core.graphics.text_2d("Editor:", constants.vec2.new(x, y), constants.FONT_SIZE, col, false)
                    y = y + 22
                    core.graphics.text_2d("Coming soon.", constants.vec2.new(x, y), constants.FONT_SIZE, soft, false)
                end
            end
        end)
    end
    -- Keep launcher mode in constants
    if launcher_mode_combo and launcher_mode_combo.get then
        local idx = launcher_mode_combo:get()
        if idx == 1 or idx == 2 or idx == 3 then
            constants.launcher_mode = idx
        else
            constants.launcher_mode = 1
        end
        persist.save_plugin({
            launcher_mode = constants.launcher_mode,
            sidebar_top_offset = constants.SIDEBAR_TOP_OFFSET or 80,
            palette_top_offset = constants.PALETTE_TOP_OFFSET or 120,
            palette_left_offset = constants.PALETTE_LEFT_OFFSET or 0
        })
    else
        constants.launcher_mode = constants.launcher_mode or 1
    end

    -- Toggle settings with F3
    if settings_gui and core.input and core.input.is_key_pressed then
        local VK_F3 = 114 -- 0x72
        if core.input.is_key_pressed(VK_F3) then
            -- Simple debouncing: require mouse click release edge simulation via stored state
            _G.__lxui_prev_f3 = _G.__lxui_prev_f3 or false
            if not _G.__lxui_prev_f3 then
                settings_gui.is_open = not settings_gui.is_open
                if settings_open_checkbox and settings_open_checkbox.set then
                    settings_open_checkbox:set(settings_gui.is_open)
                end
            end
            _G.__lxui_prev_f3 = true
        else
            _G.__lxui_prev_f3 = false
        end
    end
end

-- Render loop
local function on_render()
    -- Ensure settings window has fixed position and size and does not push sidebar
    if settings_gui then
        -- Center on screen once; fixed size
        if not settings_gui._pos_initialized then
            local scr = core.graphics and core.graphics.get_screen_size and core.graphics.get_screen_size()
            if scr then
                settings_gui.x = math.max(0, math.floor((scr.x - settings_gui.width) / 2))
                settings_gui.y = math.max(0, math.floor((scr.y - settings_gui.height) / 2))
            end
            settings_gui._pos_initialized = true
        end
    end
    rendering.render_all()
end

-- Menu rendering
local function on_render_menu()
    if ui_tree and ui_tree.render then
        ui_tree:render("Lx_UI", function()
            if launcher_mode_combo and launcher_mode_combo.render then
                launcher_mode_combo:render("Launcher Mode", launcher_mode_options, "Choose how to open/manage GUIs")
            end
            -- Settings window toggle
            if settings_open_checkbox and settings_open_checkbox.render then
                settings_open_checkbox:render("Open Settings Window", "Show/Hide the Lx_UI Settings window")
                if settings_gui then
                    local state = nil
                    if settings_open_checkbox.get_state then
                        state = settings_open_checkbox:get_state()
                    end
                    if state ~= nil then
                        settings_gui.is_open = state
                    end
                end
            end
            -- Sidebar offset slider
            if constants.launcher_mode == 2 and core.menu and core.menu.slider_int then
                if not sidebar_offset_slider then
                    local max_y = 600
                    if core.graphics and core.graphics.get_screen_size then
                        local scr = core.graphics.get_screen_size()
                        if scr and scr.y then max_y = math.max(100, scr.y - 100) end
                    end
                    local initial = constants.SIDEBAR_TOP_OFFSET or 80
                    sidebar_offset_slider = core.menu.slider_int(0, max_y, initial, "lx_ui_sidebar_offset")
                end
                if sidebar_offset_slider and sidebar_offset_slider.render then
                    sidebar_offset_slider:render("Sidebar Top Offset", "Move sidebar up/down")
                    if sidebar_offset_slider.get then
                        constants.SIDEBAR_TOP_OFFSET = sidebar_offset_slider:get()
                    end
                    persist.save_plugin({
                        launcher_mode = constants.launcher_mode,
                        sidebar_top_offset = constants.SIDEBAR_TOP_OFFSET or 80,
                        palette_top_offset = constants.PALETTE_TOP_OFFSET or 120,
                        palette_left_offset = constants.PALETTE_LEFT_OFFSET or 0
                    })
                end
            end
            -- Palette offset sliders (vertical and horizontal)
            if constants.launcher_mode == 1 and core.menu and core.menu.slider_int then
                if not palette_offset_slider then
                    local max_y = 800
                    if core.graphics and core.graphics.get_screen_size then
                        local scr = core.graphics.get_screen_size()
                        if scr and scr.y then max_y = math.max(100, scr.y - 60) end
                    end
                    local initial = constants.PALETTE_TOP_OFFSET or 120
                    palette_offset_slider = core.menu.slider_int(0, max_y, initial, "lx_ui_palette_offset")
                end
                if palette_offset_slider and palette_offset_slider.render then
                    palette_offset_slider:render("Palette Top Offset", "Move palette up/down")
                    if palette_offset_slider.get then
                        constants.PALETTE_TOP_OFFSET = palette_offset_slider:get()
                    end
                    persist.save_plugin({
                        launcher_mode = constants.launcher_mode,
                        sidebar_top_offset = constants.SIDEBAR_TOP_OFFSET or 80,
                        palette_top_offset = constants.PALETTE_TOP_OFFSET or 120,
                        palette_left_offset = constants.PALETTE_LEFT_OFFSET or 0
                    })
                end
                if not palette_left_slider then
                    local max_x = 800
                    if core.graphics and core.graphics.get_screen_size then
                        local scr = core.graphics.get_screen_size()
                        if scr and scr.x then max_x = scr.x end
                    end
                    palette_left_slider = core.menu.slider_int(-math.floor(max_x/2), math.floor(max_x/2), constants.PALETTE_LEFT_OFFSET or 0, "lx_ui_palette_left")
                end
                if palette_left_slider and palette_left_slider.render then
                    palette_left_slider:render("Palette Left/Right Offset", "Move palette left/right")
                    if palette_left_slider.get then
                        constants.PALETTE_LEFT_OFFSET = palette_left_slider:get()
                    end
                    persist.save_plugin({
                        launcher_mode = constants.launcher_mode,
                        sidebar_top_offset = constants.SIDEBAR_TOP_OFFSET or 80,
                        palette_top_offset = constants.PALETTE_TOP_OFFSET or 120,
                        palette_left_offset = constants.PALETTE_LEFT_OFFSET or 0
                    })
                end
            end
            -- Per-GUI enable/disable toggles
            for name, checkbox in pairs(constants.gui_states) do
                if checkbox and checkbox.render then
                    local before = nil
                    if checkbox.get_state then before = checkbox:get_state() elseif checkbox.get then before = checkbox:get() end
                    checkbox:render("Enable " .. tostring(name), "Show/hide this GUI window")
                    local after = nil
                    if checkbox.get_state then after = checkbox:get_state() elseif checkbox.get then after = checkbox:get() end
                    if before ~= after then
                        -- Persist enabled state with window files
                        if constants.registered_guis[name] then
                            persist.save_window(constants.registered_guis[name])
                        end
                    end
                end
            end
            rendering.render_menu_controls()
        end)
    end
end

-- Public API (avoid global unless needed; keep a module table)
local Lx_UI = {
    Menu = Menu,
    register = function(name, width, height, unique_key)
        local gui = Menu:new(name, width, height, unique_key)
        -- Load per-window settings
        local cfg = persist.load_window(gui)
        if cfg.x then gui.x = tonumber(cfg.x) or gui.x end
        if cfg.y then gui.y = tonumber(cfg.y) or gui.y end
        if cfg.width then gui.width = tonumber(cfg.width) or gui.width end
        if cfg.height then gui.height = tonumber(cfg.height) or gui.height end
        if cfg.is_open ~= nil then gui.is_open = not not cfg.is_open end
        -- restore launcher enable checkbox state
        if cfg.enabled ~= nil then
            local chk = constants.gui_states[name]
            if chk and chk.set then
                chk:set(not not cfg.enabled)
            end
        end
        if cfg.slot and name ~= "Lx_UI Settings" then
            constants.launcher_assignments[name] = tostring(cfg.slot)
        end

        -- Hook movement save on next frame when dragging ends (handled in rendering via flags)
        gui._on_after_move = function()
            persist.save_window(gui)
        end
        return gui
    end,
    isInputBlocked = function()
        return helpers.is_input_blocked()
    end,
    _persist_assignments = function()
        -- Save per-window files reflecting current assignments and window states
        for name, gui in pairs(constants.registered_guis) do
            if name ~= "Lx_UI Settings" then
                persist.save_window(gui)
            end
        end
    end
}

-- Optionally expose globally if required by other libs
_G.Lx_UI = Lx_UI

-- Settings GUI is created lazily in on_update so it works even if menu was never opened

-- Register callbacks
core.register_on_update_callback(on_update)
core.register_on_render_callback(on_render)
core.register_on_render_menu_callback(on_render_menu)

core.log("Lx_UI loaded: modular UI system initialized")

return Lx_UI




