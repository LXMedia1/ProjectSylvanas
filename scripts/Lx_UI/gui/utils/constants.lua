-- ==================== CONSTANTS ====================

local color = require("common/color")
local vec2 = require("common/geometry/vector_2")

local Settings = {
    debug_mode = false
}

-- Font sizes
local FONT_SIZE = 14

local registered_guis = {}
local gui_states = {}

-- Invisible blocking window to prevent click-through
local blocking_window = core.menu and core.menu.window and core.menu.window("lx_ui_blocker") or nil

-- Cached tab rectangles for topbar hit-testing
local topbar_tabs = {}
local sidebar_tabs = {}
local palette_entries = {}
local palette_rect = nil
local launcher_assignments = {}
local listbox_drag = nil
local listbox_drop_handled = false

local mouse_state = {
    position = vec2.new(0, 0),
    left_down = false,
    left_clicked = false,
    last_left = false,
    right_down = false,
    right_clicked = false,
    last_right = false,
    is_over_gui = false,
}

-- Global typing flag to gate input
local is_typing = false
-- active capture rect from inputs to position hidden menu text_input in menu context
local typing_capture = nil

return {
    color = color,
    vec2 = vec2,
    Settings = Settings,
    FONT_SIZE = FONT_SIZE,
    registered_guis = registered_guis,
    gui_states = gui_states,
    blocking_window = blocking_window,
    topbar_tabs = topbar_tabs,
    sidebar_tabs = sidebar_tabs,
    palette_entries = palette_entries,
    palette_rect = palette_rect,
    launcher_assignments = launcher_assignments,
    listbox_drag = listbox_drag,
    listbox_drop_handled = listbox_drop_handled,
    mouse_state = mouse_state,
    is_typing = is_typing,
    typing_capture = typing_capture,
    launcher_mode = 1, -- 1=palette, 2=sidebar, 3=topbar
    -- Common layout
    HEADER_HEIGHT = 24,
    -- Sidebar layout defaults
    SIDEBAR_WIDTH = 160,
    SIDEBAR_ITEM_HEIGHT = 28,
    SIDEBAR_SPACING = 6,
    SIDEBAR_TOP_OFFSET = 80,
    -- Palette layout defaults
    PALETTE_WIDTH = 300,
    PALETTE_ITEM_HEIGHT = 28,
    PALETTE_SPACING = 6,
    PALETTE_TOP_OFFSET = 120,
    PALETTE_LEFT_OFFSET = 0,
    -- No external images used for headers (draw pixel art procedurally)
    logo_raw = nil -- {width,height,pixels}
    ,
    -- Settings banner defaults
    -- Settings banner removed
    SETTINGS_BANNER_HEIGHT = 0,
    SETTINGS_BANNER_MARGIN_X = 0,
    SETTINGS_BANNER_MARGIN_Y = 0
}




