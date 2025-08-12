local plugin = {}

plugin["name"] = "Test_Rider"
plugin["version"] = "0.1.0"
plugin["author"] = "Lexxes"
plugin["description"] = "Debug helper to inspect mounts and mount API behavior"
plugin["load"] = false
plugin["is_library"] = false
plugin["is_required_dependency"] = false

local local_player = core.object_manager.get_local_player()
if not local_player then
    plugin["load"] = false
    return plugin
end

return plugin


