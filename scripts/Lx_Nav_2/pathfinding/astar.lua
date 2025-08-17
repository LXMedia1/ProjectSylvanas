-- A* Pathfinding Algorithm

local Settings = require('config/settings')
local Logger = require('utils/logger')

local AStar = {}

-- Priority queue implementation
local PriorityQueue = {}
PriorityQueue.__index = PriorityQueue

function PriorityQueue:new()
    return setmetatable({items = {}, size = 0}, self)
end

function PriorityQueue:push(item, priority)
    table.insert(self.items, {item = item, priority = priority})
    self.size = self.size + 1
    self:_bubble_up(self.size)
end

function PriorityQueue:pop()
    if self.size == 0 then return nil end
    
    local root = self.items[1].item
    self.items[1] = self.items[self.size]
    self.items[self.size] = nil
    self.size = self.size - 1
    
    if self.size > 0 then
        self:_bubble_down(1)
    end
    
    return root
end

function PriorityQueue:empty()
    return self.size == 0
end

function PriorityQueue:_bubble_up(index)
    while index > 1 do
        local parent = math.floor(index / 2)
        if self.items[index].priority < self.items[parent].priority then
            self.items[index], self.items[parent] = self.items[parent], self.items[index]
            index = parent
        else
            break
        end
    end
end

function PriorityQueue:_bubble_down(index)
    while true do
        local smallest = index
        local left = 2 * index
        local right = 2 * index + 1
        
        if left <= self.size and self.items[left].priority < self.items[smallest].priority then
            smallest = left
        end
        
        if right <= self.size and self.items[right].priority < self.items[smallest].priority then
            smallest = right
        end
        
        if smallest ~= index then
            self.items[index], self.items[smallest] = self.items[smallest], self.items[index]
            index = smallest
        else
            break
        end
    end
end

-- Find path using A* algorithm
function AStar.find_path(graph, start_id, goal_id, heuristic_fn)
    if not graph:get_node(start_id) or not graph:get_node(goal_id) then
        Logger:warning("Invalid start or goal node")
        return nil
    end
    
    -- Use provided heuristic or default to Euclidean distance
    heuristic_fn = heuristic_fn or function(node_a, node_b)
        return node_a.center:dist_to(node_b.center)
    end
    
    local open_set = PriorityQueue:new()
    local came_from = {}
    local g_score = {}
    local f_score = {}
    local closed_set = {}
    
    -- Initialize start node
    g_score[start_id] = 0
    f_score[start_id] = heuristic_fn(
        graph:get_node(start_id),
        graph:get_node(goal_id)
    )
    open_set:push(start_id, f_score[start_id])
    
    local iterations = 0
    local max_iterations = Settings.get("pathfinding.max_iterations") or 5000
    
    while not open_set:empty() and iterations < max_iterations do
        iterations = iterations + 1
        
        local current = open_set:pop()
        
        -- Goal reached
        if current == goal_id then
            return AStar._reconstruct_path(came_from, current)
        end
        
        closed_set[current] = true
        
        -- Explore neighbors
        local edges = graph:get_edges(current)
        for _, edge in ipairs(edges) do
            local neighbor = edge.to
            
            if not closed_set[neighbor] then
                local tentative_g = g_score[current] + edge.cost
                
                if not g_score[neighbor] or tentative_g < g_score[neighbor] then
                    came_from[neighbor] = current
                    g_score[neighbor] = tentative_g
                    
                    local h = heuristic_fn(
                        graph:get_node(neighbor),
                        graph:get_node(goal_id)
                    )
                    f_score[neighbor] = tentative_g + h
                    
                    -- Add to open set
                    open_set:push(neighbor, f_score[neighbor])
                end
            end
        end
    end
    
    if iterations >= max_iterations then
        Logger:warning("A* reached max iterations: " .. max_iterations)
    end
    
    return nil -- No path found
end

-- Reconstruct path from came_from map
function AStar._reconstruct_path(came_from, current)
    local path = {current}
    
    while came_from[current] do
        current = came_from[current]
        table.insert(path, 1, current)
    end
    
    return path
end

-- Find K alternative paths using Yen's algorithm
function AStar.find_k_paths(graph, start_id, goal_id, k, heuristic_fn)
    k = k or 3
    local paths = {}
    
    -- Find the shortest path first
    local shortest = AStar.find_path(graph, start_id, goal_id, heuristic_fn)
    if not shortest then
        return paths
    end
    
    table.insert(paths, shortest)
    
    -- Find alternative paths
    local candidates = PriorityQueue:new()
    
    for k_idx = 2, k do
        local prev_path = paths[#paths]
        
        for i = 1, #prev_path - 1 do
            local spur_node = prev_path[i]
            local root_path = {}
            
            -- Get root path
            for j = 1, i do
                root_path[j] = prev_path[j]
            end
            
            -- Temporarily remove edges used in previous paths
            local removed_edges = {}
            for _, path in ipairs(paths) do
                if AStar._path_matches_root(path, root_path) then
                    local edge_from = path[i]
                    local edge_to = path[i + 1]
                    if edge_from and edge_to then
                        -- Store and remove edge
                        local edges = graph:get_edges(edge_from)
                        for idx, edge in ipairs(edges) do
                            if edge.to == edge_to then
                                table.insert(removed_edges, {
                                    from = edge_from,
                                    edge = edge,
                                    index = idx
                                })
                                table.remove(edges, idx)
                                break
                            end
                        end
                    end
                end
            end
            
            -- Find spur path
            local spur_path = AStar.find_path(graph, spur_node, goal_id, heuristic_fn)
            
            -- Restore removed edges
            for _, removal in ipairs(removed_edges) do
                local edges = graph:get_edges(removal.from)
                table.insert(edges, removal.index, removal.edge)
            end
            
            -- Create complete path
            if spur_path and #spur_path > 1 then
                local total_path = {}
                
                -- Add root path (excluding spur node)
                for j = 1, i - 1 do
                    table.insert(total_path, root_path[j])
                end
                
                -- Add spur path
                for j = 1, #spur_path do
                    table.insert(total_path, spur_path[j])
                end
                
                -- Calculate path cost
                local cost = AStar._calculate_path_cost(graph, total_path)
                candidates:push(total_path, cost)
            end
        end
        
        -- Add best candidate to result
        if not candidates:empty() then
            local best = candidates:pop()
            if not AStar._path_exists(paths, best) then
                table.insert(paths, best)
            end
        else
            break -- No more paths available
        end
    end
    
    return paths
end

-- Check if path matches root
function AStar._path_matches_root(path, root)
    if #path < #root then return false end
    
    for i = 1, #root do
        if path[i] ~= root[i] then
            return false
        end
    end
    
    return true
end

-- Calculate total path cost
function AStar._calculate_path_cost(graph, path)
    local cost = 0
    
    for i = 1, #path - 1 do
        local edges = graph:get_edges(path[i])
        for _, edge in ipairs(edges) do
            if edge.to == path[i + 1] then
                cost = cost + edge.cost
                break
            end
        end
    end
    
    return cost
end

-- Check if path already exists in list
function AStar._path_exists(paths, new_path)
    for _, path in ipairs(paths) do
        if #path == #new_path then
            local same = true
            for i = 1, #path do
                if path[i] ~= new_path[i] then
                    same = false
                    break
                end
            end
            if same then return true end
        end
    end
    return false
end

return AStar