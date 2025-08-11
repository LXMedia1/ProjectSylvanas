-- Lx_UI_Prev: minimal preview of Lx_UI base window

local Lx_UI = _G.Lx_UI

if not Lx_UI or not Lx_UI.register then
    core.log_warning("Lx_UI not available; preview will not run")
    return
end

local preview_gui = Lx_UI.register("Lx_UI Preview", 460, 320, "lx_ui_preview")

-- Second preview window to validate multi-window topbar behaviour
local preview_gui_2 = Lx_UI.register("Second Preview", 420, 280, "lx_ui_preview_2")

core.log("Lx_UI_Prev initialized (opened preview window)")


