-- Lx_UI API Plugin Header
local plugin = {}

plugin["name"] = "lx_ui"
plugin["author"] = "Lexxes"
plugin["version"] = "0.1"
plugin["description"] = "UI library providing floating windows, input handling, and persistence hooks"

plugin["load"] = true
plugin["is_library"] = true
plugin["is_required_dependency"] = true

-- Basic validation to ensure we can load
if core and core.object_manager then
    local local_player = core.object_manager.get_local_player()
    if not local_player then
        plugin["load"] = false
        return plugin
    end
end

return plugin




