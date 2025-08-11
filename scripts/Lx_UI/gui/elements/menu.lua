local constants = require("gui/utils/constants")
local Label = require("gui/components/label")
local Tabs = require("gui/components/tabs")
local Button = require("gui/components/button")
local Checkbox = require("gui/components/checkbox")
local Panel = require("gui/components/panel")
local Listbox = require("gui/components/listbox")
local Combobox = require("gui/components/combobox")

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

return {
    Menu = Menu
}




