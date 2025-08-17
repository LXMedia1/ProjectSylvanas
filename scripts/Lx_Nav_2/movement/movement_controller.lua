-- Movement Controller

local vec3 = require('common/geometry/vector_3')
local Settings = require('config/settings')
local Logger = require('utils/logger')
local Profiler = require('utils/profiler')

local MovementController = {}
MovementController.__index = MovementController

function MovementController:new()
    local obj = {
        current_path = nil,
        current_index = 1,
        is_moving = false,
        stuck_detector = nil,
        last_position = nil,
        last_move_time = 0,
        on_finish_callback = nil,
        on_stuck_callback = nil
    }
    setmetatable(obj, self)
    
    -- Initialize stuck detector
    obj.stuck_detector = {
        position = nil,
        time = 0,
        threshold_time = Settings.get("movement.stuck_threshold") or 2.0,
        threshold_dist = Settings.get("movement.stuck_distance") or 0.5
    }
    
    return obj
end

-- Start following a path
function MovementController:start_path(path, on_finish, on_stuck)
    if not path or #path < 2 then
        Logger:warning("Invalid path provided to movement controller")
        return false
    end
    
    self.current_path = path
    self.current_index = 1
    self.is_moving = true
    self.on_finish_callback = on_finish
    self.on_stuck_callback = on_stuck
    
    -- Reset stuck detector
    self.stuck_detector.position = nil
    self.stuck_detector.time = 0
    
    Logger:debug("Started following path with " .. #path .. " nodes")
    return true
end

-- Stop movement
function MovementController:stop()
    self.is_moving = false
    self.current_path = nil
    self.current_index = 1
    self:release_inputs()
    
    Logger:debug("Movement stopped")
end

-- Update movement (called each frame)
function MovementController:update()
    if not self.is_moving or not self.current_path then
        return
    end
    
    local player = core.object_manager and core.object_manager.get_local_player()
    if not player then
        self:stop()
        return
    end
    
    local player_pos = player:get_position()
    if not player_pos then
        return
    end
    
    -- Check if stuck
    if self:check_stuck(player_pos) then
        Logger:warning("Player is stuck")
        if self.on_stuck_callback then
            self.on_stuck_callback()
        end
        self:stop()
        return
    end
    
    -- Get current target
    local target = self:get_current_target()
    if not target then
        self:finish_movement()
        return
    end
    
    -- Check arrival at current node
    local arrive_dist = Settings.get("movement.arrive_distance") or 1.5
    if player_pos:distance(target) <= arrive_dist then
        self:advance_to_next_node()
        target = self:get_current_target()
        
        if not target then
            self:finish_movement()
            return
        end
    end
    
    -- Move towards target
    self:move_to_point(target, player_pos)
end

-- Get current target node
function MovementController:get_current_target()
    if not self.current_path or self.current_index > #self.current_path then
        return nil
    end
    
    -- Look ahead to smoother target
    local lookahead = math.min(self.current_index + 1, #self.current_path)
    return self.current_path[lookahead]
end

-- Advance to next node in path
function MovementController:advance_to_next_node()
    self.current_index = self.current_index + 1
    
    if self.current_index > #self.current_path then
        Logger:debug("Reached end of path")
    else
        Logger:debug("Advanced to node " .. self.current_index .. "/" .. #self.current_path)
    end
end

-- Move towards a point
function MovementController:move_to_point(target, player_pos)
    if not target or not player_pos then return end
    
    local direction = (target - player_pos):normalize()
    
    -- Face target if enabled
    if Settings.get("movement.use_look_at") then
        self:face_direction(direction)
    end
    
    -- Apply movement
    self:apply_movement(direction)
    
    -- Update last move time
    self.last_move_time = Profiler.get_time_ms()
end

-- Face a direction
function MovementController:face_direction(direction)
    if not direction then return end
    
    -- Calculate yaw from direction
    local yaw = math.atan2(direction.y, direction.x)
    
    -- Apply facing (implementation depends on game API)
    if core.player and core.player.set_facing then
        core.player.set_facing(yaw)
    end
end

-- Apply movement input
function MovementController:apply_movement(direction)
    if not direction then return end
    
    -- This is game-specific implementation
    -- Example using WASD keys:
    local threshold = 0.1
    
    -- Forward/Backward
    if math.abs(direction.x) > threshold then
        if direction.x > 0 then
            self:press_key("W") -- Forward
            self:release_key("S")
        else
            self:press_key("S") -- Backward
            self:release_key("W")
        end
    else
        self:release_key("W")
        self:release_key("S")
    end
    
    -- Left/Right strafe
    if math.abs(direction.y) > threshold then
        if direction.y > 0 then
            self:press_key("D") -- Right
            self:release_key("A")
        else
            self:press_key("A") -- Left
            self:release_key("D")
        end
    else
        self:release_key("A")
        self:release_key("D")
    end
end

-- Press a key
function MovementController:press_key(key)
    if core.input and core.input.press then
        core.input.press(key)
    end
end

-- Release a key
function MovementController:release_key(key)
    if core.input and core.input.release then
        core.input.release(key)
    end
end

-- Release all movement inputs
function MovementController:release_inputs()
    local keys = {"W", "A", "S", "D"}
    for _, key in ipairs(keys) do
        self:release_key(key)
    end
end

-- Check if player is stuck
function MovementController:check_stuck(player_pos)
    local current_time = Profiler.get_time_ms() / 1000 -- Convert to seconds
    
    if not self.stuck_detector.position then
        self.stuck_detector.position = player_pos
        self.stuck_detector.time = current_time
        return false
    end
    
    local distance = player_pos:distance(self.stuck_detector.position)
    local time_diff = current_time - self.stuck_detector.time
    
    if distance > self.stuck_detector.threshold_dist then
        -- Player moved, reset detector
        self.stuck_detector.position = player_pos
        self.stuck_detector.time = current_time
        return false
    end
    
    -- Check if stuck for too long
    if time_diff > self.stuck_detector.threshold_time then
        return true
    end
    
    return false
end

-- Finish movement
function MovementController:finish_movement()
    self:stop()
    
    Logger:info("Movement completed")
    
    if self.on_finish_callback then
        self.on_finish_callback()
    end
end

-- Get progress along path (0-1)
function MovementController:get_progress()
    if not self.current_path or #self.current_path == 0 then
        return 0
    end
    
    return (self.current_index - 1) / #self.current_path
end

-- Is currently moving
function MovementController:is_active()
    return self.is_moving
end

-- Get remaining path
function MovementController:get_remaining_path()
    if not self.current_path then
        return nil
    end
    
    local remaining = {}
    for i = self.current_index, #self.current_path do
        table.insert(remaining, self.current_path[i])
    end
    
    return remaining
end

return MovementController