local constants = require("gui/utils/constants")

local Listbox = {}
Listbox.__index = Listbox

function Listbox:new(owner_gui, x, y, w, h, items, on_change, title, list_type)
    local o = setmetatable({}, Listbox)
    o.gui = owner_gui
    o.x = tonumber(x or 0) or 0
    o.y = tonumber(y or 0) or 0
    o.w = tonumber(w or 160) or 160
    o.h = tonumber(h or 120) or 120
    o.items = items or {}
    o.on_change = on_change
    o.selected_index = nil
    o.visible_if = nil
    o.row_height = (constants.FONT_SIZE or 14) + 6
    o.accepts_drop = true
    o.id = tostring(owner_gui.name or "gui") .. "_lb_" .. tostring(math.random(1000000))
    o.title = tostring(title or "")
    o.header_h = 18
    -- Drag/drop grouping. Only listboxes with the same type_id accept drops from each other
    o.type_id = list_type
    -- Optional semantic drop slot (e.g. "default" | "topbar" | "sidebar" | "palette")
    o.drop_slot = nil
    return o
end

function Listbox:set_items(items)
    self.items = items or {}
    if self.selected_index and (self.selected_index < 1 or self.selected_index > #self.items) then
        self.selected_index = nil
    end
end

function Listbox:set_on_change(cb)
    self.on_change = cb
end

function Listbox:set_visible_if(fn)
    self.visible_if = fn
end

-- Drag/drop type helpers
function Listbox:setType(type_id)
    self.type_id = type_id
    return self
end

function Listbox:getType()
    return self.type_id
end

function Listbox:setDropSlot(slot)
    self.drop_slot = slot
    return self
end

function Listbox:is_visible()
    if self.visible_if then return not not self.visible_if(self) end
    return true
end

function Listbox:get_selected_index()
    return self.selected_index
end

function Listbox:get_selected_text()
    if self.selected_index and self.items[self.selected_index] then
        return tostring(self.items[self.selected_index])
    end
    return nil
end

function Listbox:set_selected_index(idx)
    local new_idx = tonumber(idx)
    if new_idx and new_idx >= 1 and new_idx <= #self.items then
        if new_idx ~= self.selected_index then
            self.selected_index = new_idx
            if self.on_change then
                self.on_change(self, new_idx, tostring(self.items[new_idx]))
            end
        end
    end
end

function Listbox:render()
    if not (self.gui and self.gui.is_open and self:is_visible()) then return end
    if not core.graphics then return end

    local gx = self.gui.x + self.x
    local gy = self.gui.y + self.y
    local gw = self.w
    local gh = self.h

    local col_bg = constants.color.new(18, 24, 40, 225)
    local col_border = constants.color.new(18, 22, 30, 220)
    local col_row = constants.color.new(36, 52, 96, 235)
    local col_row_hover = constants.color.new(56, 88, 150, 255)
    local col_row_selected = constants.color.new(92, 128, 205, 255)
    local col_text = constants.color.white(255)
    local col_header = constants.color.new(44, 64, 110, 210)

    if core.graphics.rect_2d_filled then
        core.graphics.rect_2d_filled(constants.vec2.new(gx, gy), gw, gh, col_bg, 6)
        if self.title ~= "" then
            core.graphics.rect_2d_filled(constants.vec2.new(gx, gy), gw, self.header_h, col_header, 6)
        end
    end
    if core.graphics.rect_2d then
        core.graphics.rect_2d(constants.vec2.new(gx, gy), gw, gh, col_border, 1, 6)
        if self.title ~= "" then
            core.graphics.rect_2d(constants.vec2.new(gx, gy + self.header_h), gw, 1, col_border, 1, 0)
        end
    end
    if self.title ~= "" and core.graphics.text_2d then
        local tx = gx + 8
        local ty = gy + math.floor((self.header_h - (constants.FONT_SIZE or 14)) / 2) - 1
        core.graphics.text_2d(self.title, constants.vec2.new(tx, ty), constants.FONT_SIZE, col_text, false)
    end

    local mouse = constants.mouse_state.position
    local is_dragging = constants.listbox_drag ~= nil
    local same_type_drag = is_dragging and constants.listbox_drag.type_id ~= nil and self.type_id ~= nil and constants.listbox_drag.type_id == self.type_id
    local over_listbox = (mouse.x >= gx and mouse.x <= gx + gw and mouse.y >= gy and mouse.y <= gy + gh)

    -- Visualize potential drop target when dragging a compatible item
    if same_type_drag and over_listbox then
        local col_drop_border = constants.color.new(120, 200, 255, 255)
        local col_drop_fill = constants.color.new(80, 120, 200, 40)
        if core.graphics.rect_2d_filled then
            core.graphics.rect_2d_filled(constants.vec2.new(gx + 2, gy + 2), gw - 4, gh - 4, col_drop_fill, 6)
        end
        if core.graphics.rect_2d then
            core.graphics.rect_2d(constants.vec2.new(gx, gy), gw, gh, col_drop_border, 2, 6)
        end
    end
    local rows_fit = math.max(0, math.floor((gh - self.header_h - 4) / self.row_height))
    local count = math.min(rows_fit, #self.items)
    local y = gy + self.header_h + 2
    for i = 1, count do
        local item = tostring(self.items[i])
        local hovered = (mouse.x >= gx and mouse.x <= gx + gw and mouse.y >= y and mouse.y <= y + self.row_height)
        local is_sel = (self.selected_index == i)
        local fill = is_sel and col_row_selected or (hovered and col_row_hover or col_row)
        if core.graphics.rect_2d_filled then
            core.graphics.rect_2d_filled(constants.vec2.new(gx + 2, y), gw - 4, self.row_height - 2, fill, 4)
        end
        if core.graphics.text_2d then
            local tx = gx + 8
            local ty = y + math.floor((self.row_height - (constants.FONT_SIZE or 14)) / 2) - 1
            core.graphics.text_2d(item, constants.vec2.new(tx, ty), constants.FONT_SIZE, col_text, false)
        end
        if hovered then
            if constants.mouse_state.left_down and constants.listbox_drag == nil then
                -- start drag immediately on press
                self:set_selected_index(i)
                constants.listbox_drag = { source = self, text = item, index = i, type_id = self.type_id }
                if core and core.log then core.log("[Lx_UI] Listbox drag start from '" .. (self.title or "") .. "' item '" .. item .. "'") end
            end
        end
        y = y + self.row_height
    end

    -- Ghost is drawn at the end of the GUI render so it appears on top; nothing to draw here

    -- Drop handling: if a drag exists and mouse released over this listbox, move item
    if constants.listbox_drag and not constants.mouse_state.left_down then
        local m = constants.mouse_state.position
        local over = (m.x >= gx and m.x <= gx + gw and m.y >= gy and m.y <= gy + gh)
        if over and constants.listbox_drag.source ~= self then
            local payload = constants.listbox_drag
            local same_type = (payload.type_id ~= nil and self.type_id ~= nil and payload.type_id == self.type_id)
            if self.accepts_drop and same_type then
                -- Update central assignment map if present, using the target drop slot
                if self.drop_slot and constants.launcher_assignments then
                    constants.launcher_assignments[payload.text] = self.drop_slot
                end
                -- Remove from source items array if present
                if payload and payload.source and payload.source.items then
                    for si = #payload.source.items, 1, -1 do
                        if tostring(payload.source.items[si]) == tostring(payload.text or "") then
                            table.remove(payload.source.items, si)
                            break
                        end
                    end
                end
                -- Deduplicate in target then insert
                if self.items then
                    for ti = #self.items, 1, -1 do
                        if tostring(self.items[ti]) == tostring(payload and payload.text or "") then
                            table.remove(self.items, ti)
                        end
                    end
                    table.insert(self.items, tostring(payload and payload.text or ""))
                end
                -- Notify listeners
                if self.on_change and payload then self.on_change(self, nil, payload.text) end
                -- Persist assignment change immediately via window save utility if available
                if _G and _G.Lx_UI and _G.Lx_UI._persist_assignments then _G.Lx_UI._persist_assignments() end
                constants.listbox_drop_handled = true
                if core and core.log then core.log("[Lx_UI] Listbox dropped '" .. tostring(payload.text) .. "' into '" .. (self.title or "") .. "'") end
            end
        end
        -- Do not clear here; a centralized cleanup will run after all listboxes rendered
    end
end

return Listbox


