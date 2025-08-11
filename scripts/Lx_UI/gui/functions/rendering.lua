local constants = require("gui/utils/constants")
local input = require("gui/functions/input")
local helpers = require("gui/utils/helpers")

-- Helper: detect CTRL key state (supports generic and L/R variants)
local function is_ctrl_down()
    if not core.input or not core.input.is_key_pressed then return false end
    local VK_CONTROL = 17   -- 0x11
    local VK_LCONTROL = 162 -- 0xA2
    local VK_RCONTROL = 163 -- 0xA3
    return core.input.is_key_pressed(VK_CONTROL)
        or core.input.is_key_pressed(VK_LCONTROL)
        or core.input.is_key_pressed(VK_RCONTROL)
end

local function render_window(gui)
    -- No external image loading; header art is drawn procedurally
    -- background
    local bg = constants.color.new(20, 20, 30, 220)
    if core.graphics.rect_2d_filled then
        local origin = constants.vec2.new(gui.x, gui.y)
        core.graphics.rect_2d_filled(origin, gui.width, gui.height, bg, 3)
    end
    -- header bar
    local hb = constants.color.new(40, 60, 100, 240)
    if core.graphics.rect_2d_filled then
        local origin = constants.vec2.new(gui.x, gui.y)
        core.graphics.rect_2d_filled(origin, gui.width, 24, hb, 3)
    end
    -- header height cached for layout
    local header_h = constants.HEADER_HEIGHT or 24
    -- space for left-side move icon
    local icon_size = 16
    if core.graphics.text_2d then
        local text_x = gui.x + 8 + icon_size + 8
        local title_y = gui.y + 5
        -- If settings banner present, ensure the content text below header aligns after banner
        core.graphics.text_2d(gui.name or "Window", constants.vec2.new(text_x, title_y), constants.FONT_SIZE, constants.color.white(255), false)
    end

    -- Drag handling via a small move icon on the LEFT side only
    local mouse = constants.mouse_state.position
    -- same icon size as reserved above
    local icon_x = gui.x + 7
    local icon_y = gui.y + math.floor((24 - icon_size) / 2)
    local icon_hovered = helpers.is_point_in_rect(mouse.x, mouse.y, icon_x, icon_y, icon_size, icon_size)
    -- Optional dragging: disabled for fixed windows
    if not gui.is_fixed then
        gui._dragging = gui._dragging or false
        if icon_hovered and constants.mouse_state.left_down and not gui._dragging then
            gui._dragging = true
            gui._drag_off_x = mouse.x - gui.x
            gui._drag_off_y = mouse.y - gui.y
        end
        if gui._dragging then
            if constants.mouse_state.left_down then
                local new_x = mouse.x - (gui._drag_off_x or 0)
                local new_y = mouse.y - (gui._drag_off_y or 0)
                -- clamp to screen
                if core.graphics and core.graphics.get_screen_size then
                    local screen = core.graphics.get_screen_size()
                    new_x = math.max(0, math.min(new_x, screen.x - gui.width))
                    new_y = math.max(0, math.min(new_y, screen.y - gui.height))
                end
                gui.x = new_x
                gui.y = new_y
            else
                gui._dragging = false
                if gui._on_after_move then gui._on_after_move() end
            end
        end
    end

    -- Draw a fine, crisp cross-arrows icon at the left side (1px lines, no border)
    if core.graphics.line_2d and not gui.is_fixed then
        local cx = icon_x + math.floor(icon_size / 2)
        local cy = icon_y + math.floor(icon_size / 2)
        local c = constants.color.new(245, 245, 255, icon_hovered and 255 or 230)
        local shaft_len = 6   -- half-length of the shafts
        local head_len = 3    -- arrow head length
        local gap = 1         -- 1px gap at center for symmetry
        local w = 1           -- line width for fine look

        -- shafts split at center (prevents thicker center pixel)
        core.graphics.line_2d(constants.vec2.new(cx - shaft_len, cy), constants.vec2.new(cx - gap, cy), c, w)
        core.graphics.line_2d(constants.vec2.new(cx + gap, cy), constants.vec2.new(cx + shaft_len, cy), c, w)
        core.graphics.line_2d(constants.vec2.new(cx, cy - shaft_len), constants.vec2.new(cx, cy - gap), c, w)
        core.graphics.line_2d(constants.vec2.new(cx, cy + gap), constants.vec2.new(cx, cy + shaft_len), c, w)

        -- uniform line arrow heads (tips outside shaft ends)
        -- right
        core.graphics.line_2d(constants.vec2.new(cx + shaft_len + head_len, cy), constants.vec2.new(cx + shaft_len, cy - head_len), c, w)
        core.graphics.line_2d(constants.vec2.new(cx + shaft_len + head_len, cy), constants.vec2.new(cx + shaft_len, cy + head_len), c, w)
        -- left
        core.graphics.line_2d(constants.vec2.new(cx - shaft_len - head_len, cy), constants.vec2.new(cx - shaft_len, cy - head_len), c, w)
        core.graphics.line_2d(constants.vec2.new(cx - shaft_len - head_len, cy), constants.vec2.new(cx - shaft_len, cy + head_len), c, w)
        -- up
        core.graphics.line_2d(constants.vec2.new(cx, cy - shaft_len - head_len), constants.vec2.new(cx - head_len, cy - shaft_len), c, w)
        core.graphics.line_2d(constants.vec2.new(cx, cy - shaft_len - head_len), constants.vec2.new(cx + head_len, cy - shaft_len), c, w)
        -- down
        core.graphics.line_2d(constants.vec2.new(cx, cy + shaft_len + head_len), constants.vec2.new(cx - head_len, cy + shaft_len), c, w)
        core.graphics.line_2d(constants.vec2.new(cx, cy + shaft_len + head_len), constants.vec2.new(cx + head_len, cy + shaft_len), c, w)
    end
    -- content rendering via window-specific callback
    if gui.render_callback then
        gui.render_callback(gui)
    end

    -- render components (tabs first, then containers, then widgets)
    if gui._tabbars then
        for i = 1, #gui._tabbars do
            local tb = gui._tabbars[i]
            if tb and tb.render then tb:render() end
        end
    end
    if gui._panels then
        for i = 1, #gui._panels do
            local p = gui._panels[i]
            if p and p.render then p:render() end
        end
    end
    if gui._buttons then
        for i = 1, #gui._buttons do
            local b = gui._buttons[i]
            if b and b.render then b:render() end
        end
    end
    if gui._checkboxes then
        for i = 1, #gui._checkboxes do
            local c = gui._checkboxes[i]
            if c and c.render then c:render() end
        end
    end
    if gui._sliders then
        for i = 1, #gui._sliders do
            local s = gui._sliders[i]
            if s and s.render then s:render() end
        end
    end
    -- Draw listboxes first (their panels), then draw comboboxes so dropdowns appear above
    if gui._listboxes then
        for i = 1, #gui._listboxes do
            local lb = gui._listboxes[i]
            if lb and lb.render then lb:render() end
        end
    end
    if gui._comboboxes then
        for i = 1, #gui._comboboxes do
            local cb = gui._comboboxes[i]
            if cb and cb.render then cb:render() end
        end
    end
    -- After all listboxes for this gui rendered, if a drop was handled this frame and mouse is up, clear drag payload
    if constants.listbox_drag and not constants.mouse_state.left_down then
        if constants.listbox_drop_handled then
            constants.listbox_drag = nil
            constants.listbox_drop_handled = false
        end
    end
    if gui._labels then
        for i = 1, #gui._labels do
            local lbl = gui._labels[i]
            if lbl and lbl.render then lbl:render() end
        end
    end

    -- Draw listbox drag ghost last so it appears above all GUI content
    if constants.listbox_drag and constants.listbox_drag.source and constants.listbox_drag.source.gui == gui then
        local ghost_text = tostring(constants.listbox_drag.text or "")
        if ghost_text ~= "" and core.graphics and core.graphics.text_2d then
            local mouse = constants.mouse_state.position
            local row_h = (constants.FONT_SIZE or 14) + 6
            local ghost_bg = constants.color.new(20, 30, 50, 200)
            local ghost_bd = constants.color.new(120, 190, 255, 230)
            local tw = (core.graphics.get_text_width and core.graphics.get_text_width(ghost_text, constants.FONT_SIZE, 0)) or 60
            local pad = 6
            local box_w = tw + pad * 2
            local box_h = row_h - 2
            local bx = mouse.x + 14
            local by = mouse.y + 10
            if core.graphics.rect_2d_filled then
                core.graphics.rect_2d_filled(constants.vec2.new(bx, by), box_w, box_h, ghost_bg, 4)
            end
            if core.graphics.rect_2d then
                core.graphics.rect_2d(constants.vec2.new(bx, by), box_w, box_h, ghost_bd, 1, 4)
            end
            local tx = bx + pad
            local ty = by + math.floor((box_h - (constants.FONT_SIZE or 14)) / 2) - 1
            core.graphics.text_2d(ghost_text, constants.vec2.new(tx, ty), constants.FONT_SIZE, constants.color.white(255), false)
        end
    end
end

local function render_topbar()
    if not core.graphics or not core.graphics.get_screen_size then return end
    local screen = core.graphics.get_screen_size()
    local bar_h = 28
    local origin = constants.vec2.new(0, 0)

    -- collect visible tabs first to compute centered layout
    local tabs = {}
    for name, gui in pairs(constants.registered_guis) do
        local enabled = true
        local chk = constants.gui_states[name]
        if chk then
            if chk.get_state then enabled = chk:get_state() elseif chk.get then enabled = chk:get() end
        end
        if gui.is_hidden_from_launcher then enabled = false end
        -- filter by launcher assignment:
        -- Show items assigned to topbar always; show default only when Topbar is the selected launcher
        local slot = (constants.launcher_assignments and constants.launcher_assignments[name]) or "default"
        local mode = (constants.launcher_mode or 1)
        local allowed = (slot == "topbar" or (slot == "default" and mode == 3))
        if enabled and allowed then
            local label = name
            local text_w = (core.graphics.get_text_width and core.graphics.get_text_width(label, constants.FONT_SIZE, 0)) or 60
            -- Give tabs a generous width so text can truly center inside
            local tab_w = math.max(text_w + 40, 120)
            table.insert(tabs, { name = name, gui = gui, label = label, width = tab_w, text_w = text_w })
        end
    end
    if #tabs == 0 then return end

    -- compute total width and center
    local spacing = 12
    local total_w = 0
    for i = 1, #tabs do
        total_w = total_w + tabs[i].width
        if i < #tabs then total_w = total_w + spacing end
    end
    local start_x = math.max(0, math.floor((screen.x - total_w) / 2))

    -- invisible (transparent) bar background (no divider line)

    -- colors
    local col_text = constants.color.white(255)
    local col_text_inactive = constants.color.new(220,220,230,220)
    local col_tab = constants.color.new(64, 94, 160, 230)
    local col_tab_hover = constants.color.new(86, 120, 200, 240)
    local col_tab_inactive = constants.color.new(36, 46, 70, 190)
    local col_border = constants.color.new(18, 22, 30, 220)
    local col_gloss = constants.color.new(255, 255, 255, 18)
    local col_shadow = constants.color.new(0, 0, 0, 90)
    local col_accent = constants.color.new(120, 200, 255, 255)

    -- layout centered tabs
    local mouse = constants.mouse_state.position
    constants.topbar_tabs = {}
    local x = start_x
    local y = 0
    for _, t in ipairs(tabs) do
        local tab_rect_x = x
        local tab_rect_y = 0
        local tab_rect_w = t.width
        local hovered = (mouse.x >= tab_rect_x and mouse.x <= tab_rect_x + tab_rect_w and mouse.y >= tab_rect_y and mouse.y <= tab_rect_y + bar_h - 4)
        local is_active = t.gui.is_open
        local bg = is_active and col_tab or (hovered and col_tab_hover or col_tab_inactive)

        -- base rounded button
        if core.graphics.rect_2d_filled then
            -- Draw outer border rectangle (full height) for a crisp edge
            core.graphics.rect_2d(constants.vec2.new(tab_rect_x, tab_rect_y), tab_rect_w, bar_h, col_border, 1, 0)
            -- Inner fill inset by 1px on top/bottom to ensure content stays inside
            local inner_y = tab_rect_y + 1
            local inner_h = bar_h - 2
            core.graphics.rect_2d_filled(constants.vec2.new(tab_rect_x, inner_y), tab_rect_w, inner_h, bg, 0)
            -- top light line inside the border
            core.graphics.rect_2d(constants.vec2.new(tab_rect_x, inner_y), tab_rect_w, 1, col_gloss, 1, 0)
        end
        -- bottom shadow line to add depth
        if core.graphics.rect_2d then
            core.graphics.rect_2d(constants.vec2.new(tab_rect_x + 2, tab_rect_y + bar_h - 6), tab_rect_w - 4, 1, col_shadow, 1, 0)
        end
        -- active underline accent
        if is_active and core.graphics.rect_2d_filled then
            local underline_y = tab_rect_y + bar_h - 3 -- 2px above bottom border
            core.graphics.rect_2d_filled(constants.vec2.new(tab_rect_x + 6, underline_y), tab_rect_w - 12, 2, col_accent, 0)
        end

        -- label centered within tab (both axes), clamped fully inside
        local measured_w = (core.graphics.get_text_width and core.graphics.get_text_width(t.label, constants.FONT_SIZE, 0)) or t.text_w
        local inner_y = tab_rect_y + 1
        local inner_h = bar_h - 2
        -- pure centering inside the visible filled area (avoid padding bias)
        -- move start position by half the text width to the right relative to tab left
        local text_x = tab_rect_x + math.floor((tab_rect_w / 2) - (measured_w / 2) + 0.5)
        local text_y = inner_y + math.floor(((inner_h - constants.FONT_SIZE) / 2) + 0.5) - 2
        -- clamp just inside the border
        local min_x = tab_rect_x + 2
        local max_x = tab_rect_x + tab_rect_w - 2 - measured_w
        if text_x < min_x then text_x = min_x end
        if text_x > max_x then text_x = max_x end
        if core.graphics.text_2d then
            local txt_col = is_active and col_text or col_text_inactive
            core.graphics.text_2d(t.label, constants.vec2.new(text_x, text_y), constants.FONT_SIZE, txt_col, false)
        end
        -- store for hit-testing
        table.insert(constants.topbar_tabs, { name = t.name, x = tab_rect_x, y = tab_rect_y, w = tab_rect_w, h = bar_h - 4, gui = t.gui })
        x = x + tab_rect_w + spacing
    end
end

-- Sidebar launcher (mode 2)
local function render_sidebar()
    if not core.graphics or not core.graphics.get_screen_size then return end
    local screen = core.graphics.get_screen_size()
    local w = constants.SIDEBAR_WIDTH or 160
    local item_h = constants.SIDEBAR_ITEM_HEIGHT or 28
    local spacing = constants.SIDEBAR_SPACING or 6

    local x = 8 -- slight inset from the very left edge
    local y = (constants.SIDEBAR_TOP_OFFSET or 80) -- user adjustable

    -- colors
    local col_panel = constants.color.new(18, 24, 40, 180)
    local col_border = constants.color.new(18, 22, 30, 220)
    local col_item = constants.color.new(36, 52, 96, 220)
    local col_item_hover = constants.color.new(56, 88, 150, 240)
    local col_item_active = constants.color.new(70, 110, 190, 240)
    local col_text = constants.color.white(255)
    local col_text_inactive = constants.color.new(220, 220, 230, 220)

    -- panel background (auto height for now)
    local num_enabled = 0
    for name, gui in pairs(constants.registered_guis) do
        local chk = constants.gui_states[name]
        local enabled = true
        if chk then
            if chk.get_state then enabled = chk:get_state() elseif chk.get then enabled = chk:get() end
        end
        if gui and gui.is_hidden_from_launcher then enabled = false end
        local slot = (constants.launcher_assignments and constants.launcher_assignments[name]) or "default"
        local mode = (constants.launcher_mode or 1)
        local allowed = (slot == "sidebar" or (slot == "default" and mode == 2))
        if enabled and allowed then num_enabled = num_enabled + 1 end
    end
    if num_enabled == 0 then return end
    local panel_h = num_enabled * item_h + math.max(0, num_enabled - 1) * spacing + 16
    if core.graphics.rect_2d_filled then
        core.graphics.rect_2d_filled(constants.vec2.new(x - 6, y - 8), w + 12, panel_h, col_panel, 6)
        core.graphics.rect_2d(constants.vec2.new(x - 6, y - 8), w + 12, panel_h, col_border, 1, 6)
    end

    constants.sidebar_tabs = {}
    local mouse = constants.mouse_state.position
    local cur_y = y
    for name, gui in pairs(constants.registered_guis) do
        local chk = constants.gui_states[name]
        local enabled = true
        if chk then
            if chk.get_state then enabled = chk:get_state() elseif chk.get then enabled = chk:get() end
        end
        if gui.is_hidden_from_launcher then enabled = false end
        local slot = (constants.launcher_assignments and constants.launcher_assignments[name]) or "default"
        local mode = (constants.launcher_mode or 1)
        local allowed = (slot == "sidebar" or (slot == "default" and mode == 2))
        if enabled and allowed then
            local hovered = (mouse.x >= x and mouse.x <= x + w and mouse.y >= cur_y and mouse.y <= cur_y + item_h)
            local bg = gui.is_open and col_item_active or (hovered and col_item_hover or col_item)
            if core.graphics.rect_2d_filled then
                core.graphics.rect_2d_filled(constants.vec2.new(x, cur_y), w, item_h, bg, 4)
                core.graphics.rect_2d(constants.vec2.new(x, cur_y), w, item_h, col_border, 1, 4)
            end
            -- text centered vertically, padded left
            local label = name
            local text_w = (core.graphics.get_text_width and core.graphics.get_text_width(label, constants.FONT_SIZE, 0)) or 60
            local text_x = x + 10
            local text_y = cur_y + math.floor((item_h - constants.FONT_SIZE) / 2) - 1
            if core.graphics.text_2d then
                local tc = gui.is_open and col_text or col_text_inactive
                core.graphics.text_2d(label, constants.vec2.new(text_x, text_y), constants.FONT_SIZE, tc, false)
            end
            table.insert(constants.sidebar_tabs, { name = name, x = x, y = cur_y, w = w, h = item_h, gui = gui })
            cur_y = cur_y + item_h + spacing
        end
    end
end

-- Palette launcher (mode 1)
local function render_palette()
    if not core.graphics or not core.graphics.get_screen_size then return end
    local screen = core.graphics.get_screen_size()
    local w = constants.PALETTE_WIDTH or 300
    local item_h = constants.PALETTE_ITEM_HEIGHT or 28
    local spacing = constants.PALETTE_SPACING or 6
    -- center horizontally, add user left/right offset
    local x = math.floor((screen.x - w) / 2) + (constants.PALETTE_LEFT_OFFSET or 0)
    local y = (constants.PALETTE_TOP_OFFSET or 120)

    local col_panel = constants.color.new(18, 24, 40, 200)
    local col_border = constants.color.new(18, 22, 30, 220)
    local col_item = constants.color.new(36, 52, 96, 220)
    local col_item_hover = constants.color.new(56, 88, 150, 240)
    local col_item_active = constants.color.new(70, 110, 190, 240)
    local col_text = constants.color.white(255)
    local col_text_inactive = constants.color.new(220, 220, 230, 220)

    -- Compute enabled count
    local entries = {}
    for name, gui in pairs(constants.registered_guis) do
        local chk = constants.gui_states[name]
        local enabled = true
        if chk then
            if chk.get_state then enabled = chk:get_state() elseif chk.get then enabled = chk:get() end
        end
        if gui.is_hidden_from_launcher then enabled = false end
        local slot = (constants.launcher_assignments and constants.launcher_assignments[name]) or "default"
        local mode = (constants.launcher_mode or 1)
        local allowed = (slot == "palette" or (slot == "default" and mode == 1))
        if enabled and allowed then table.insert(entries, { name = name, gui = gui }) end
    end
    if #entries == 0 then
        constants.palette_rect = nil
        return
    end
    local panel_h = #entries * item_h + math.max(0, #entries - 1) * spacing + 16
    constants.palette_rect = { x = x - 8, y = y - 8, w = w + 16, h = panel_h }
    if core.graphics.rect_2d_filled then
        core.graphics.rect_2d_filled(constants.vec2.new(x - 8, y - 8), w + 16, panel_h, col_panel, 8)
        core.graphics.rect_2d(constants.vec2.new(x - 8, y - 8), w + 16, panel_h, col_border, 1, 8)
    end

    constants.palette_entries = {}
    local mouse = constants.mouse_state.position
    local cur_y = y
    for _, e in ipairs(entries) do
        local hovered = (mouse.x >= x and mouse.x <= x + w and mouse.y >= cur_y and mouse.y <= cur_y + item_h)
        local bg = e.gui.is_open and col_item_active or (hovered and col_item_hover or col_item)
        if core.graphics.rect_2d_filled then
            core.graphics.rect_2d_filled(constants.vec2.new(x, cur_y), w, item_h, bg, 4)
            core.graphics.rect_2d(constants.vec2.new(x, cur_y), w, item_h, col_border, 1, 4)
        end
        local label = e.name
        local text_w = (core.graphics.get_text_width and core.graphics.get_text_width(label, constants.FONT_SIZE, 0)) or 60
        local text_x = x + math.floor((w - text_w) / 2)
        local text_y = cur_y + math.floor((item_h - constants.FONT_SIZE) / 2) - 1
        if core.graphics.text_2d then
            local tc = e.gui.is_open and col_text or col_text_inactive
            core.graphics.text_2d(label, constants.vec2.new(text_x, text_y), constants.FONT_SIZE, tc, false)
        end
        table.insert(constants.palette_entries, { name = e.name, x = x, y = cur_y, w = w, h = item_h, gui = e.gui })
        cur_y = cur_y + item_h + spacing
    end
end

local function render_all()
    input.update_mouse()
    -- reset drag flags at frame start (will be set by listboxes on drop)
    constants.listbox_drop_handled = false

    -- Render an invisible blocking window under EACH open & enabled GUI to prevent click-through
    if core.menu and core.menu.window then
        for name, gui in pairs(constants.registered_guis) do
            local enabled_checkbox = constants.gui_states[name]
            local enabled = true
            if enabled_checkbox then
                if enabled_checkbox.get_state then
                    enabled = enabled_checkbox:get_state()
                elseif enabled_checkbox.get then
                    enabled = enabled_checkbox:get()
                end
            end
            -- Always allow blocker for non-launcher windows like settings (even if no checkbox)
            if gui.is_hidden_from_launcher then enabled = gui.is_open or enabled end
            if gui.is_open and enabled then
                local bw = gui.blocking_window
                if bw and bw.stop_forcing_size then
                    bw:stop_forcing_size()
                    bw:force_next_begin_window_pos(constants.vec2.new(gui.x, gui.y))
                    bw:set_next_window_min_size(constants.vec2.new(gui.width, gui.height))
                    bw:force_window_size(constants.vec2.new(gui.width, gui.height))
                end
                if bw and bw.set_background_multicolored then
                    local c = constants.color.new(0,0,0,0)
                    bw:set_background_multicolored(c,c,c,c)
                end
                if bw and bw.begin then
                    bw:begin(
                        0,
                        false,
                        constants.color.new(0,0,0,0),
                        constants.color.new(0,0,0,0),
                        0,
                        (core.enums and core.enums.window_enums and core.enums.window_enums.window_behaviour_flags and core.enums.window_enums.window_behaviour_flags.NO_MOVE) or 0,
                        0,
                        0,
                        function()
                            if bw.add_artificial_item_bounds then
                                bw:add_artificial_item_bounds(constants.vec2.new(0,0), constants.vec2.new(gui.width, gui.height))
                            end
                        end
                    )
                end
            end
        end
    end

    for name, gui in pairs(constants.registered_guis) do
        local enabled_checkbox = constants.gui_states[name]
        local enabled = true
        if enabled_checkbox then
            if enabled_checkbox.get_state then
                enabled = enabled_checkbox:get_state()
            elseif enabled_checkbox.get then
                enabled = enabled_checkbox:get()
            end
        end
        -- Always render settings and other internal windows when open (no launcher checkbox)
        if gui.is_open and enabled then
            render_window(gui)
        end
    end
    -- Draw all launcher UIs that have items; default items appear only in the active launcher
    -- Topbar
    render_topbar()
    do
        local mouse = constants.mouse_state.position
        for _, tab in ipairs(constants.topbar_tabs or {}) do
            local hovered = (mouse.x >= tab.x and mouse.x <= tab.x + tab.w and mouse.y >= tab.y and mouse.y <= tab.y + tab.h)
            if hovered and constants.mouse_state.left_clicked then
                if is_ctrl_down() then
                    tab.gui.is_open = not tab.gui.is_open
                else
                    if tab.gui.is_open then
                        tab.gui.is_open = false
                    else
                        for _, g in pairs(constants.registered_guis) do if g ~= tab.gui then g.is_open = false end end
                        tab.gui.is_open = true
                    end
                end
                if _G and _G.Lx_UI and _G.Lx_UI._persist_assignments then _G.Lx_UI._persist_assignments() end
            end
        end
    end
    -- Sidebar
    render_sidebar()
    do
        local mouse = constants.mouse_state.position
        for _, tab in ipairs(constants.sidebar_tabs or {}) do
            local hovered = (mouse.x >= tab.x and mouse.x <= tab.x + tab.w and mouse.y >= tab.y and mouse.y <= tab.y + tab.h)
            if hovered and constants.mouse_state.left_clicked then
                if is_ctrl_down() then
                    tab.gui.is_open = not tab.gui.is_open
                else
                    if tab.gui.is_open then
                        tab.gui.is_open = false
                    else
                        for _, g in pairs(constants.registered_guis) do if g ~= tab.gui then g.is_open = false end end
                        tab.gui.is_open = true
                    end
                end
                if _G and _G.Lx_UI and _G.Lx_UI._persist_assignments then _G.Lx_UI._persist_assignments() end
            end
        end
    end
    -- Palette
    render_palette()
    do
        local mouse = constants.mouse_state.position
        for _, ent in ipairs(constants.palette_entries or {}) do
            local hovered = (mouse.x >= ent.x and mouse.x <= ent.x + ent.w and mouse.y >= ent.y and mouse.y <= ent.y + ent.h)
            if hovered and constants.mouse_state.left_clicked then
                if is_ctrl_down() then
                    ent.gui.is_open = not ent.gui.is_open
                else
                    if ent.gui.is_open then
                        ent.gui.is_open = false
                    else
                        for _, g in pairs(constants.registered_guis) do if g ~= ent.gui then g.is_open = false end end
                        ent.gui.is_open = true
                    end
                end
                if _G and _G.Lx_UI and _G.Lx_UI._persist_assignments then _G.Lx_UI._persist_assignments() end
            end
        end
    end
    -- end-of-frame cleanup for listbox drag payload
    if not constants.mouse_state.left_down then
        constants.listbox_drag = nil
        constants.listbox_drop_handled = false
    end
end

local function render_menu_controls()
    -- Intentionally empty for now
end

return {
    render_all = render_all,
    render_menu_controls = render_menu_controls
}




