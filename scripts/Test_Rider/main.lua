-- Lua 5.1; use only scripts/.api

-- UI state
local ui = {
  menu = nil,
  btn_refresh = nil,
  btn_dismount = nil,
  txt_mount_index = nil,
  btn_mount_idx = nil,
  btn_random_ground = nil,
  btn_random_fly = nil,
  btn_random_swim = nil,
}

local function log_mount_info(index, info)
  if not info then
    core.log_warning("[Test_Rider] nil mount info at index=" .. tostring(index))
    return
  end
  local parts = {
    "index=" .. tostring(index),
    "name='" .. tostring(info.mount_name) .. "'",
    "spell_id=" .. tostring(info.spell_id),
    "mount_id=" .. tostring(info.mount_id),
    "active=" .. tostring(info.is_active),
    "usable=" .. tostring(info.is_usable),
    "type=" .. tostring(info.mount_type),
  }
  core.log("[Test_Rider] " .. table.concat(parts, ", "))
end

local function refresh_mount_list()
  local count = core.spell_book.get_mount_count()
  local usable_count = 0
  usable_by_category = { ground = {}, fly = {}, swim = {} }
  for i = 1, count do
    local info = core.spell_book.get_mount_info(i)
    if info and info.is_usable then
      usable_count = usable_count + 1
      local category = nil
      if info.mount_type == 230 then
        category = "ground"
      elseif info.mount_type == 231 then
        category = "swim"
      elseif info.mount_type == 424 or info.mount_type == 402 then
        category = "fly"
      end
      if category then
        local list = usable_by_category[category]
        list[#list + 1] = i
      end
    end
  end
  local ground_n = #usable_by_category.ground
  local swim_n = #usable_by_category.swim
  local fly_n = #usable_by_category.fly
  core.log("[Test_Rider] Usable mounts: " .. tostring(usable_count) .. " / " .. tostring(count)
    .. " | ground=" .. tostring(ground_n)
    .. ", swim=" .. tostring(swim_n)
    .. ", fly=" .. tostring(fly_n))
  for i = 1, count do
    local info = core.spell_book.get_mount_info(i)
    if info and info.is_usable then
      log_mount_info(i, info)
    end
  end
  local player = core.object_manager.get_local_player()
  if player and player.is_mounted and player:is_mounted() then
    core.log("[Test_Rider] Player is mounted = true")
  else
    core.log("[Test_Rider] Player is mounted = false")
  end
end

local function try_mount_from_text()
  if not ui.txt_mount_index or not ui.txt_mount_index.get_text then
    core.log_warning("[Test_Rider] text input not ready")
    return
  end
  local txt = ui.txt_mount_index:get_text()
  local idx = tonumber(txt)
  if not idx then
    core.log_warning("[Test_Rider] invalid mount index: '" .. tostring(txt) .. "'")
    return
  end
  core.log("[Test_Rider] Trying to mount index=" .. tostring(idx))
  core.input.mount(idx)
end

local function mount_random(category)
  if not usable_by_category then
    core.log_warning("[Test_Rider] No cached mount list, press Refresh first")
    return
  end
  local list = usable_by_category[category]
  if not list or #list == 0 then
    core.log_warning("[Test_Rider] No usable " .. tostring(category) .. " mounts available")
    return
  end
  math.randomseed(core.time())
  local pick = list[math.random(1, #list)]
  core.log("[Test_Rider] Random " .. tostring(category) .. " mount index=" .. tostring(pick))
  core.input.mount(pick)
end

core.register_on_render_menu_callback(function()
  if not ui.menu then
    ui.menu = core.menu.tree_node()
    ui.btn_refresh = core.menu.button("test_rider_refresh")
    ui.btn_dismount = core.menu.button("test_rider_dismount")
    ui.txt_mount_index = core.menu.text_input("test_rider_mount_index", true)
    ui.btn_mount_idx = core.menu.button("test_rider_mount_idx")
    ui.btn_random_ground = core.menu.button("test_rider_random_ground")
    ui.btn_random_fly = core.menu.button("test_rider_random_fly")
    ui.btn_random_swim = core.menu.button("test_rider_random_swim")
  end

  ui.menu:render("Test Rider", function()
    ui.btn_refresh:render("Refresh & Log Mounts")
    if ui.btn_refresh:is_clicked() then
      refresh_mount_list()
    end

    ui.btn_dismount:render("Dismount")
    if ui.btn_dismount:is_clicked() then
      core.input.dismount()
      core.log("[Test_Rider] Dismount requested")
    end

    ui.txt_mount_index:render("Mount index (number)")
    ui.btn_mount_idx:render("Mount by index")
    if ui.btn_mount_idx:is_clicked() then
      try_mount_from_text()
    end

    ui.btn_random_ground:render("Random Ground Mount")
    if ui.btn_random_ground:is_clicked() then
      mount_random("ground")
    end

    ui.btn_random_fly:render("Random Fly Mount")
    if ui.btn_random_fly:is_clicked() then
      mount_random("fly")
    end

    ui.btn_random_swim:render("Random Swim Mount")
    if ui.btn_random_swim:is_clicked() then
      mount_random("swim")
    end
  end)
end)


