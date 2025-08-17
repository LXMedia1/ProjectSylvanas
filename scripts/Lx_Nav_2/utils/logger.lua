-- Logging Utilities

local Settings = require('config/settings')

local Logger = {}
Logger.__index = Logger

function Logger:new(name)
    local obj = {
        name = name or "Lx_Nav_2",
        enabled = false
    }
    setmetatable(obj, self)
    return obj
end

function Logger:set_enabled(enabled)
    self.enabled = enabled
end

function Logger:log(message)
    if self.enabled and Settings.get("debug.log_enabled") then
        core.log("[" .. self.name .. "] " .. message)
    end
end

function Logger:info(message)
    if self.enabled and Settings.get("debug.log_enabled") then
        core.log("[" .. self.name .. "] " .. message)
    end
end

function Logger:warning(message)
    if self.enabled and Settings.get("debug.log_enabled") then
        core.log_warning("[" .. self.name .. "] " .. message)
    end
end

function Logger:error(message)
    -- Always log errors
    core.log_error("[" .. self.name .. "] " .. message)
end

function Logger:debug(message)
    if self.enabled and Settings.get("debug.enabled") then
        core.log("[" .. self.name .. "][DEBUG] " .. message)
    end
end

-- Create singleton instance
local instance = Logger:new()

return instance