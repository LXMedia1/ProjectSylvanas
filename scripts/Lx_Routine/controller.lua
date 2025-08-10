local Targeting = require('Lx_Routine/targeting')

local Controller = {}
Controller.__index = Controller

function Controller.new(engine)
  local self = setmetatable({}, Controller)
  self.engine = engine
  self.nav = nil
  self.moving = false
  return self
end

local function get_ctx(engine)
  if engine and engine.context_provider then
    local ok, ctx = pcall(engine.context_provider)
    if ok and type(ctx) == 'table' then return ctx end
  end
  return { engine = engine }
end

local function ensure_nav()
  if _G.Lx_Nav and _G.Lx_Nav.init and not Controller.__nav_inited then
    Controller.__nav_inited = true
    return _G.Lx_Nav.init()
  end
  return nil
end

function Controller:start()
  -- lazy nav init
  self.nav = ensure_nav()

  core.register_on_update_callback(function()
    if not self.engine or not self.engine.is_running then return end
    local ctx = get_ctx(self.engine)

    -- 1) Target selection
    local target = (ctx.target and ctx.target) or nil
    local target_valid = target and target.is_enemy and not target.is_dead
    if not target_valid then
      local best = Targeting.select_best_target(ctx)
      if best then
        if ctx.set_target then ctx.set_target(best) end
        ctx.target = best
        target = best
        target_valid = true
      end
    end

    -- 2) Movement to pull/engage (optional)
    if target_valid then
      if ctx.is_in_range and target and (not ctx.is_in_range(585, target)) then
        -- Move towards target; prefer nav if available
        local pos = target.get_position and target:get_position() or nil
        if pos then
          if self.nav and self.nav.move_to then
            self.nav.move_to(pos, false)
          elseif ctx.move_to then
            ctx.move_to(pos)
          end
        end
      else
        -- In range; stop movement if we were moving
        if self.nav and self.nav.stop then self.nav.stop() end
      end

      -- 3) Ensure facing
      if target and target.get_position then
        if ctx.face then
          ctx.face(target)
        elseif core and core.input and core.input.look_at then
          local p = target:get_position()
          if p then core.input.look_at(p) end
        end
      end
    end
  end)
end

return Controller


