-- Lx_Nav_2 Plugin Header
local plugin = {}

plugin["name"] = "Lx_Nav_2"
plugin["author"] = "Lexxes"
plugin["version"] = "2.0.0"
plugin["description"] = "Advanced navigation library with improved architecture"

plugin["load"] = true
plugin["is_library"] = true
plugin["is_required_dependency"] = false

-- Validation
if core and core.object_manager then
    local local_player = core.object_manager.get_local_player()
    if not local_player then
        plugin["load"] = false
        return plugin
    end
end

return plugin