-- Lua 5.1; sandboxed API only

local M = {}

local cache = {
  ground = {},
  swim = {},
  fly = {},
  by_index = {},
  initialized = false,
}

local function categorize_mount(info)
  if not info or not info.is_usable then return nil end
  if info.mount_type == 230 then return "ground" end
  if info.mount_type == 231 then return "swim" end
  if info.mount_type == 424 or info.mount_type == 402 then return "fly" end
  return nil
end

local function refresh_if_needed()
  if cache.initialized then return end
  cache.ground, cache.swim, cache.fly, cache.by_index = {}, {}, {}, {}
  local total = core.spell_book.get_mount_count()
  for i = 1, total do
    local info = core.spell_book.get_mount_info(i)
    if info then
      cache.by_index[i] = info
      local cat = categorize_mount(info)
      if cat then
        local t = cache[cat]
        t[#t + 1] = i
      end
    end
  end
  cache.initialized = true
end

local function pick_and_mount(category)
  refresh_if_needed()
  local list = cache[category]
  if not list or #list == 0 then
    core.log_warning("[Lx_Api] No usable " .. tostring(category) .. " mounts available")
    return false
  end
  math.randomseed(core.time())
  local idx = list[math.random(1, #list)]
  local info = cache.by_index[idx]
  if info then
    core.log("[Lx_Api] Mounting '" .. tostring(info.mount_name) .. "' (" .. tostring(category) .. ")")
  else
    core.log("[Lx_Api] Mounting index " .. tostring(idx) .. " (" .. tostring(category) .. ")")
  end
  core.input.mount(idx)
  return true
end

function M.randomFly()
  return pick_and_mount("fly")
end

function M.randomGround()
  return pick_and_mount("ground")
end

function M.randomSwim()
  return pick_and_mount("swim")
end

return M


