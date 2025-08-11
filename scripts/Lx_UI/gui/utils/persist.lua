local constants = require("gui/utils/constants")

local Persist = {}

-- Paths (relative to scripts_data)
local BASE_DIR = "Lx_UI"
local WINDOWS_DIR = BASE_DIR .. "/windows"
local PLUGIN_FILE = BASE_DIR .. "/lx_ui.cfg"

local function ensure_dirs()
    if core and core.create_data_folder then
        core.create_data_folder(BASE_DIR)
        core.create_data_folder(WINDOWS_DIR)
    end
end

local function sanitize_key(s)
    s = tostring(s or "")
    s = s:lower():gsub("[^a-z0-9_%-%./]", "_")
    if s == "" then s = "window" end
    return s
end

local function window_file_for(gui)
    local key = gui.unique_key or gui.name or "window"
    key = sanitize_key(key)
    return WINDOWS_DIR .. "/" .. key .. ".cfg"
end

-- Very small key=value serializer (numbers/booleans/strings)
local function serialize(tbl)
    local lines = {}
    for k, v in pairs(tbl or {}) do
        local typ = type(v)
        if typ == "number" then
            table.insert(lines, tostring(k) .. "=" .. tostring(v))
        elseif typ == "boolean" then
            table.insert(lines, tostring(k) .. "=" .. (v and "true" or "false"))
        elseif typ == "string" then
            local s = v:gsub("\n", "\\n"):gsub("\r", "\\r")
            table.insert(lines, tostring(k) .. "=\"" .. s .. "\"")
        end
    end
    return table.concat(lines, "\n")
end

local function parse(content)
    local out = {}
    if not content or #content == 0 then return out end
    for line in string.gmatch(content, "[^\n]+") do
        local k, rest = string.match(line, "^%s*([%w_%-%./]+)%s*=%s*(.+)%s*$")
        if k then
            local val = rest
            if string.sub(val, 1, 1) == '"' and string.sub(val, -1) == '"' then
                val = string.sub(val, 2, -2)
                val = val:gsub("\\n", "\n"):gsub("\\r", "\r")
            elseif val == "true" then
                val = true
            elseif val == "false" then
                val = false
            else
                local num = tonumber(val)
                if num ~= nil then val = num end
            end
            out[k] = val
        end
    end
    return out
end

local last_plugin_snapshot = nil
local last_window_snapshots = {}

function Persist.ensure_dirs()
    ensure_dirs()
end

function Persist.load_plugin()
    ensure_dirs()
    local data = core.read_data_file(PLUGIN_FILE) or ""
    local t = parse(data)
    if not t.default_launcher or (t.default_launcher ~= "sidebar" and t.default_launcher ~= "palette" and t.default_launcher ~= "topbar") then
        t.default_launcher = "sidebar"
    end
    constants.__default_launcher = t.default_launcher
    return t
end

function Persist.save_plugin(cfg)
    ensure_dirs()
    -- avoid redundant writes
    local need = true
    if last_plugin_snapshot then
        need = false
        for k, v in pairs(cfg) do
            if last_plugin_snapshot[k] ~= v then need = true break end
        end
        for k, v in pairs(last_plugin_snapshot) do
            if cfg[k] ~= v then need = true break end
        end
    end
    if not need then return end
    core.create_data_file(PLUGIN_FILE)
    local snap = {}
    for k, v in pairs(cfg) do snap[k] = v end
    if not snap.default_launcher then
        snap.default_launcher = constants.__default_launcher or "sidebar"
    else
        constants.__default_launcher = snap.default_launcher
    end
    core.write_data_file(PLUGIN_FILE, serialize(snap))
    last_plugin_snapshot = {}
    for k, v in pairs(snap) do last_plugin_snapshot[k] = v end
end

function Persist.load_window(gui)
    ensure_dirs()
    if gui.is_settings then return {} end
    local path = window_file_for(gui)
    local data = core.read_data_file(path) or ""
    return parse(data)
end

function Persist.save_window(gui, extra)
    ensure_dirs()
    if gui.is_settings then return end
    local path = window_file_for(gui)
    local snapshot = last_window_snapshots[path]
    local enabled = true
    local chk = constants.gui_states and constants.gui_states[gui.name]
    if chk then
        if chk.get_state then enabled = not not chk:get_state() elseif chk.get then enabled = not not chk:get() end
    end
    local cfg = {
        x = gui.x,
        y = gui.y,
        width = gui.width,
        height = gui.height,
        is_open = not not gui.is_open,
        slot = (constants.launcher_assignments and constants.launcher_assignments[gui.name]) or "default",
        enabled = enabled
    }
    if extra then
        for k, v in pairs(extra) do cfg[k] = v end
    end
    local need = true
    if snapshot then
        need = false
        for k, v in pairs(cfg) do
            if snapshot[k] ~= v then need = true break end
        end
        for k, v in pairs(snapshot) do
            if cfg[k] ~= v then need = true break end
        end
    end
    if not need then return end
    core.create_data_file(path)
    core.write_data_file(path, serialize(cfg))
    last_window_snapshots[path] = cfg
end

return Persist


