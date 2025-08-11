local plugin = {}

plugin["name"] = "Lx_Nav_Exemple"
plugin["version"] = "1.0.0"
plugin["author"] = "Lexxer"
plugin["description"] = "Example plugin showing how to use _G.Lx_Nav API"
plugin["load"] = false
plugin["is_library"] = false
plugin["is_required_dependency"] = false

local local_player = core.object_manager.get_local_player()
if not local_player then
    plugin["load"] = false
    return plugin
end

return plugin


