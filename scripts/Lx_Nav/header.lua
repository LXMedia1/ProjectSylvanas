local plugin = {}

plugin["name"] = "Lx_Nav"
plugin["version"] = "1.0.0"
plugin["author"] = "Lexxer"
plugin["description"] = "Professional standalone navigation library with advanced pathfinding and human-like movement"
plugin["load"] = true
plugin["is_library"] = true
plugin["is_required_dependency"] = true

local local_player = core.object_manager.get_local_player()
if not local_player then
    plugin["load"] = false
    return plugin
end

return plugin
