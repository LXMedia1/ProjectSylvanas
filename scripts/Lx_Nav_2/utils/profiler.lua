-- Performance Profiling Utilities

local Profiler = {}

-- Convert CPU ticks to milliseconds
function Profiler.ticks_to_ms(ticks)
    local hz = core.cpu_ticks_per_second and core.cpu_ticks_per_second() or 0
    if not hz or hz <= 0 then return 0.0 end
    return (ticks * 1000.0) / hz
end

-- Get current time in milliseconds
function Profiler.get_time_ms()
    if core.cpu_tick then
        return Profiler.ticks_to_ms(core.cpu_tick())
    elseif core.time then
        return core.time()
    else
        return 0
    end
end

-- Simple timer class
local Timer = {}
Timer.__index = Timer

function Timer:new()
    local obj = {
        start_time = nil,
        elapsed = 0
    }
    setmetatable(obj, self)
    return obj
end

function Timer:start()
    self.start_time = Profiler.get_time_ms()
    self.elapsed = 0
end

function Timer:stop()
    if self.start_time then
        self.elapsed = Profiler.get_time_ms() - self.start_time
        self.start_time = nil
    end
    return self.elapsed
end

function Timer:get_elapsed()
    if self.start_time then
        return Profiler.get_time_ms() - self.start_time
    end
    return self.elapsed
end

function Timer:is_running()
    return self.start_time ~= nil
end

-- Budget tracker for frame-limited operations
local BudgetTracker = {}
BudgetTracker.__index = BudgetTracker

function BudgetTracker:new(budget_ms)
    local obj = {
        budget_ms = budget_ms or 1.0,
        start_time = nil
    }
    setmetatable(obj, self)
    return obj
end

function BudgetTracker:start()
    self.start_time = Profiler.get_time_ms()
end

function BudgetTracker:has_budget()
    if not self.start_time then return true end
    return (Profiler.get_time_ms() - self.start_time) < self.budget_ms
end

function BudgetTracker:get_remaining()
    if not self.start_time then return self.budget_ms end
    local elapsed = Profiler.get_time_ms() - self.start_time
    return math.max(0, self.budget_ms - elapsed)
end

-- Export classes
Profiler.Timer = Timer
Profiler.BudgetTracker = BudgetTracker

return Profiler