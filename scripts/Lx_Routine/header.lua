local plugin = {}

plugin["name"] = "Lx_Routine"
plugin["version"] = "0.1.0"
plugin["author"] = "Lexxes"
plugin["description"] = "Adaptive PvE fight routine for all classes (Retail)"
plugin["load"] = true
plugin["is_library"] = true
plugin["is_required_dependency"] = false

local local_player = core.object_manager.get_local_player()
if not local_player then
    plugin["load"] = false
    return plugin
end

return plugin


