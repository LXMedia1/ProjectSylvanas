-- Lx_UI_Prev: minimal preview of Lx_UI base window

local Lx_UI = _G.Lx_UI
local color = require("common/color")
local vec2 = require("common/geometry/vector_2")

if not Lx_UI or not Lx_UI.register then
    core.log_warning("Lx_UI not available; preview will not run")
    return
end

local preview_gui = Lx_UI.register("Lx_UI Preview", 900, 580, "lx_ui_preview")

-- Second preview window to validate multi-window topbar behaviour
local preview_gui_2 = Lx_UI.register("Second Preview", 420, 280, "lx_ui_preview_2")

-- Demo content for preview_gui: show all components
preview_gui:set_render_callback(function(gui)
    -- Build once to avoid re-adding components every frame (caused visual stacking/lag)
    if not gui._demo_built then
        gui._demo_built = true
        -- Left column widgets
        gui._lbl_title = gui:AddLabel("Lx_UI Components Showcase", 0, 0)
        gui._sep_top = gui:AddSeparator(0, 0, gui.width - 32)
        gui._btn = gui:AddButton("Button", 0, 0, 140, 26, function() end)
        gui._chk = gui:AddCheckbox("Checkbox", 0, 0, false, function() end)
        gui._tgl = gui:AddToggle(0, 0, 46, 22, false, function() end)
        gui._rg  = gui:AddRadioGroup(0, 0, {"First","Second","Third"}, 1, function() end)
        gui._cb  = gui:AddCombobox(0, 0, 180, 24, {"One","Two","Three"}, 1, function() end, "Combo")
        gui._kb  = gui:AddKeybind(0, 0, 200, 22, "Key", function() end)
        gui._in  = gui:AddInput(0, 0, 300, 22, { text = "Text input" }, function() end)
        gui._sl  = gui:AddSlider(0, 0, 300, 0, 100, 50, function() end, { thickness = 12 })
        gui._pb  = gui:AddProgressBar(0, 0, 300, 14, 0.65)
        gui._pn  = gui:AddPanel("Panel", 0, 0, 400, 160)
        -- Right column scroll area and label
        gui._lbl_sa = gui:AddLabel("ScrollArea", 0, 0)
        gui._sa     = gui:AddScrollArea(0, 0, 100, 100)
        if gui._sa and gui._sa.set_render_content then
            -- Snap scroll to row height (18px); keep a constant top padding of 6px in drawing
            if gui._sa.set_snap then gui._sa:set_snap(18, 0) end
            gui._sa:set_render_content(function(self)
                local vx, vy, vw, vh, scroll_y = self:get_view_rect()
                local rows = 40
                local row_h, off = 18, 6
                -- Determine first visible row index and how many fit fully (offset is visual only)
                local first_idx = math.floor((scroll_y / row_h) + 0.0001) + 1
                if first_idx < 1 then first_idx = 1 end
                local rows_fit = math.max(0, math.floor(vh / row_h))
                local last_idx = math.min(rows, first_idx + rows_fit - 1)
                for i = first_idx, last_idx do
                    local ty = vy + off + (i - 1) * row_h - scroll_y
                    if core.graphics and core.graphics.text_2d then
                        core.graphics.text_2d("Row " .. tostring(i), vec2.new(vx + 8, ty), 14, color.white(230), false)
                    end
                end
                -- Content height independent of current scroll
                self:set_content_height(off + rows * row_h)
            end)
        end
    end

    -- Layout (update positions/sizes each frame based on current window size)
    local xL, y = 16, 36
    local right_pad = 16
    local mid_gap = 24
    local xR = math.max(xL + 420, math.floor(gui.width * 0.5))
    -- Title + separator
    gui._lbl_title.x, gui._lbl_title.y = xL, y
    y = y + 18
    gui._sep_top.x, gui._sep_top.y, gui._sep_top.w = xL, y, gui.width - 32
    y = y + 14
    -- Row 1: button + checkbox
    gui._btn.x, gui._btn.y = xL, y
    gui._chk.x, gui._chk.y = xL + 150, y + 4
    y = y + 34
    -- Row 2: toggle + radio
    gui._tgl.x, gui._tgl.y = xL, y
    gui._rg.x,  gui._rg.y  = xL + 60, y - 4
    y = y + 36
    -- Row 3: combo + keybind
    gui._cb.x, gui._cb.y = xL, y
    gui._kb.x, gui._kb.y = xL + 190, y
    y = y + 36
    -- Row 4: input
    gui._in.x, gui._in.y, gui._in.w = xL, y, 300
    y = y + 28
    -- Row 5: slider
    gui._sl.x, gui._sl.y, gui._sl.length = xL, y, 300
    y = y + 26
    -- Row 6: progress
    gui._pb.x, gui._pb.y, gui._pb.w = xL, y, 300
    y = y + 24
    -- Panel
    gui._pn.x, gui._pn.y, gui._pn.w, gui._pn.h = xL, y, math.min(400, xR - xL - mid_gap), 160

    -- Right column: ScrollArea
    gui._lbl_sa.x, gui._lbl_sa.y = xR, 36
    local sa_w = gui.width - xR - right_pad
    local sa_h = gui.height - 70
    gui._sa.x, gui._sa.y, gui._sa.w, gui._sa.h = xR, 54, sa_w, sa_h
end)

core.log("Lx_UI_Prev initialized (opened preview window)")


