-- Lx_UI_Prev Example Plugin Header
local plugin = {}

plugin["name"] = "lx_ui_prev"
plugin["author"] = "Lexxes"
plugin["version"] = "0.1"
plugin["description"] = "Preview/example for Lx_UI base window"

plugin["load"] = true
plugin["is_library"] = false
plugin["is_required_dependency"] = false

if core and core.object_manager then
    local local_player = core.object_manager.get_local_player()
    if not local_player then
        plugin["load"] = false
        return plugin
    end
end

return plugin


