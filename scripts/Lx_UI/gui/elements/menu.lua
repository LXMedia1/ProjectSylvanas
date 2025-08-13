local constants = require("gui/utils/constants")
local Label = require("gui/components/label")
local Tabs = require("gui/components/tabs")
local Button = require("gui/components/button")
local Checkbox = require("gui/components/checkbox")
local Panel = require("gui/components/panel")
local Listbox = require("gui/components/listbox")
local Combobox = require("gui/components/combobox")
local Slider = require("gui/components/slider")
local Input = require("gui/components/input")
local Keybind = require("gui/components/keybind")
local Toggle = require("gui/components/toggle_switch")
local RadioGroup = require("gui/components/radio_group")
local ProgressBar = require("gui/components/progress_bar")
local Separator = require("gui/components/separator")
local ScrollArea = require("gui/components/scroll_area")
local Treeview = require("gui/components/treeview")
local Window = require("gui/components/window")
local ColorPicker = require("gui/components/color_picker")
local WarningLabel = require("gui/components/warning_label")

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
        _labels = {},
        _tabbars = {},
        _text_inputs = {},
        _keybinds = {},
        blocking_window = nil,
        is_hidden_from_launcher = false
    }, Menu)

    -- Ensure a truly unique blocker id per GUI
    if core.menu and core.menu.window then
        gui.blocking_window = core.menu.window("lx_ui_blocker_" .. gui.unique_key)
    end

    constants.registered_guis[name] = gui
    -- Create a menu checkbox to enable/disable drawing for this GUI
    if core.menu and core.menu.checkbox then
        local id = "lx_ui_gui_enabled_" .. (name:lower():gsub("%s+", "_"))
        constants.gui_states[name] = core.menu.checkbox(true, id)
    end
    -- Do not modify checkbox userdata; persistence is handled after menu render
    
    -- Cleanup transient UI states when this GUI closes
    function gui:_cleanup_on_close()
        -- Clear input focus/selection and typing flag
        if self._text_inputs then
            for _, ti in ipairs(self._text_inputs) do
                ti.is_focused = false
                ti._is_selecting = false
                ti._sel_anchor = nil
                ti._mouse_was_down = false
            end
        end
        if self._sliders then
            for _, s in ipairs(self._sliders) do
                s.dragging = false
            end
        end
        -- Clear listbox drag payloads for safety
        constants.listbox_drag = nil
        constants.listbox_drop_handled = false
        -- Clear global typing state
        constants.is_typing = false
        constants.typing_capture = nil
        -- Designer/editor optional flags on this GUI, if present
        if self._ctx_open ~= nil then self._ctx_open = false end
        if self._edit_props_popup ~= nil then self._edit_props_popup = false end
        if self._inline_edit_active ~= nil then self._inline_edit_active = false end
    end

    return gui
end

function Menu:set_render_callback(cb)
    self.render_callback = cb
end

function Menu:toggle()
    self.is_open = not self.is_open
end

-- Components API
function Menu:AddLabel(text, x, y, col, font_size)
    local lbl = Label:new(self, text, x, y, col, font_size)
    table.insert(self._labels, lbl)
    return lbl
end

function Menu:AddTabs(items, y_offset)
    local tb = Tabs:new(self, items, y_offset)
    table.insert(self._tabbars, tb)
    return tb
end

function Menu:AddButton(text, x, y, w, h, on_click)
    local btn = Button:new(self, text, x, y, w, h, on_click)
    self._buttons = self._buttons or {}
    table.insert(self._buttons, btn)
    return btn
end

function Menu:AddCheckbox(label, x, y, checked, on_change)
    local cb = Checkbox:new(self, label, x, y, checked, on_change)
    self._checkboxes = self._checkboxes or {}
    table.insert(self._checkboxes, cb)
    return cb
end

function Menu:AddPanel(title, x, y, w, h)
    local p = Panel:new(self, title, x, y, w, h)
    self._panels = self._panels or {}
    table.insert(self._panels, p)
    return p
end

function Menu:AddListbox(x, y, w, h, items, on_change, title)
    local lb = Listbox:new(self, x, y, w, h, items, on_change, title)
    self._listboxes = self._listboxes or {}
    table.insert(self._listboxes, lb)
    return lb
end

function Menu:AddCombobox(x, y, w, h, items, selected_index, on_change, title)
    local cb = Combobox:new(self, x, y, w, h, items, selected_index, on_change, title)
    self._comboboxes = self._comboboxes or {}
    table.insert(self._comboboxes, cb)
    return cb
end

-- Slider (int or float). opts: { vertical=false, is_float=false, decimals=2, thickness=12 }
function Menu:AddSlider(x, y, length, min_value, max_value, value, on_change, opts)
    local s = Slider:new(self, x, y, length, min_value, max_value, value, on_change, opts)
    self._sliders = self._sliders or {}
    table.insert(self._sliders, s)
    return s
end

-- Text Input. opts: { multiline=false, text="" }
function Menu:AddInput(x, y, w, h, opts, on_change)
    local ti = Input:new(self, x, y, w, h, opts, on_change)
    self._text_inputs = self._text_inputs or {}
    table.insert(self._text_inputs, ti)
    return ti
end

function Menu:AddKeybind(x, y, w, h, label, on_change)
    local kb = Keybind:new(self, x, y, w, h, label, on_change)
    self._keybinds = self._keybinds or {}
    table.insert(self._keybinds, kb)
    return kb
end

function Menu:AddToggle(x, y, w, h, checked, on_change)
    local t = Toggle:new(self, x, y, w, h, checked, on_change)
    self._toggles = self._toggles or {}
    table.insert(self._toggles, t)
    return t
end

function Menu:AddRadioGroup(x, y, items, selected_index, on_change)
    local rg = RadioGroup:new(self, x, y, items, selected_index, on_change)
    self._radio_groups = self._radio_groups or {}
    table.insert(self._radio_groups, rg)
    return rg
end

function Menu:AddProgressBar(x, y, w, h, value)
    local pb = ProgressBar:new(self, x, y, w, h, value)
    self._progress_bars = self._progress_bars or {}
    table.insert(self._progress_bars, pb)
    return pb
end

function Menu:AddSeparator(x, y, w)
    local sp = Separator:new(self, x, y, w)
    self._separators = self._separators or {}
    table.insert(self._separators, sp)
    return sp
end

function Menu:AddTreeview(x, y, w, h, opts, on_select)
    local tv = Treeview:new(self, x, y, w, h, opts, on_select)
    self._treeviews = self._treeviews or {}
    table.insert(self._treeviews, tv)
    return tv
end

function Menu:AddScrollArea(x, y, w, h)
    local sa = ScrollArea:new(self, x, y, w, h)
    self._scroll_areas = self._scroll_areas or {}
    table.insert(self._scroll_areas, sa)
    return sa
end

function Menu:AddColorPicker(x, y, w, h, color, on_change, opts)
    local cp = ColorPicker:new(self, x, y, w, h, color, on_change, opts)
    self._color_pickers = self._color_pickers or {}
    table.insert(self._color_pickers, cp)
    return cp
end

function Menu:AddWindow(title, x, y, w, h)
    local win = Window:new(self, title, x, y, w, h)
    self._windows = self._windows or {}
    table.insert(self._windows, win)
    return win
end

function Menu:AddWarning(text, x, y, duration_ms)
    local wl = WarningLabel:new(self, text, x, y, duration_ms)
    self._warnings = self._warnings or {}
    table.insert(self._warnings, wl)
    return wl
end


return {
    Menu = Menu
}




