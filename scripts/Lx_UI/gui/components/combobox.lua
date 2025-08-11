local constants = require("gui/utils/constants")
local helpers = require("gui/utils/helpers")

local Combobox = {}
Combobox.__index = Combobox

function Combobox:new(owner_gui, x, y, w, h, items, selected_index, on_change, title)
    local o = setmetatable({}, Combobox)
    o.gui = owner_gui
    o.x = tonumber(x or 0) or 0
    o.y = tonumber(y or 0) or 0
    o.w = tonumber(w or 160) or 160
    o.h = tonumber(h or ((constants.FONT_SIZE or 14) + 8)) or ((constants.FONT_SIZE or 14) + 8)
    o.items = items or {}
    o.selected_index = tonumber(selected_index or 1) or 1
    if o.selected_index < 1 then o.selected_index = 1 end
    o.on_change = on_change
    o.row_height = (constants.FONT_SIZE or 14) + 6
    o.is_open = false
    o.visible_if = nil
    o.title = title or ""
    return o
end

function Combobox:set_items(items)
    self.items = items or {}
    if self.selected_index < 1 or self.selected_index > #self.items then
        self.selected_index = (#self.items > 0) and 1 or 0
    end
end

function Combobox:set(index)
    local idx = tonumber(index)
    if idx and idx >= 1 and idx <= #self.items then
        if idx ~= self.selected_index then
            self.selected_index = idx
            if self.on_change then self.on_change(self, idx, self.items[idx]) end
        end
    end
end

function Combobox:get()
    return self.selected_index, self.items[self.selected_index]
end

function Combobox:set_visible_if(fn)
    self.visible_if = fn
end

function Combobox:is_visible()
    if self.visible_if then return not not self.visible_if(self) end
    return true
end

function Combobox:render()
    if not (self.gui and self.gui.is_open and self:is_visible()) then return end
    if not core.graphics then return end

    local gx = self.gui.x + self.x
    local gy = self.gui.y + self.y
    local gw = self.w
    local gh = self.h

    local mouse = constants.mouse_state.position
    local over_header = helpers.is_point_in_rect(mouse.x, mouse.y, gx, gy, gw, gh)

    local col_bg = constants.color.new(16, 20, 34, 235)
    local col_border = constants.color.new(32, 40, 70, 255)
    local col_hover = constants.color.new(36, 52, 96, 235)
    local col_text = constants.color.white(255)
    local col_items_bg = constants.color.new(20, 26, 42, 245)
    local col_item_hover = constants.color.new(76, 110, 180, 255)

    -- header
    local header_bg = over_header and col_hover or col_bg
    if core.graphics.rect_2d_filled then
        core.graphics.rect_2d_filled(constants.vec2.new(gx, gy), gw, gh, header_bg, 4)
    end
    if core.graphics.rect_2d then
        core.graphics.rect_2d(constants.vec2.new(gx, gy), gw, gh, col_border, 1, 4)
    end
    -- text
    local txt = self.items[self.selected_index] or ""
    if core.graphics.text_2d then
        local tx = gx + 8
        local ty = gy + math.floor((gh - (constants.FONT_SIZE or 14)) / 2) - 1
        core.graphics.text_2d(tostring(txt), constants.vec2.new(tx, ty), constants.FONT_SIZE, col_text, false)
    end
    -- arrow indicator
    if core.graphics.triangle_2d_filled then
        local ax = gx + gw - 14
        local ay = gy + math.floor(gh / 2) - 2
        if self.is_open then
            -- up
            core.graphics.triangle_2d_filled(
                constants.vec2.new(ax - 6, ay + 4),
                constants.vec2.new(ax, ay - 2),
                constants.vec2.new(ax + 6, ay + 4),
                col_text
            )
        else
            -- down
            core.graphics.triangle_2d_filled(
                constants.vec2.new(ax - 6, ay - 2),
                constants.vec2.new(ax, ay + 4),
                constants.vec2.new(ax + 6, ay - 2),
                col_text
            )
        end
    end

    -- toggle
    if over_header and constants.mouse_state.left_clicked then
        self.is_open = not self.is_open
    end

    -- dropdown
    if self.is_open and #self.items > 0 then
        local list_h = (#self.items * self.row_height) + 4
        local ly = gy + gh + 2
        if core.graphics.rect_2d_filled then
            core.graphics.rect_2d_filled(constants.vec2.new(gx, ly), gw, list_h, col_items_bg, 4)
        end
        if core.graphics.rect_2d then
            core.graphics.rect_2d(constants.vec2.new(gx, ly), gw, list_h, col_border, 1, 4)
        end
        local cy = ly + 2
        for i = 1, #self.items do
            local ih = self.row_height
            local hovered = helpers.is_point_in_rect(mouse.x, mouse.y, gx + 2, cy, gw - 4, ih)
            if core.graphics.rect_2d_filled then
                local fill = hovered and col_item_hover or col_bg
                core.graphics.rect_2d_filled(constants.vec2.new(gx + 2, cy), gw - 4, ih - 2, fill, 3)
            end
            if core.graphics.text_2d then
                local tx = gx + 8
                local ty = cy + math.floor((ih - (constants.FONT_SIZE or 14)) / 2) - 1
                core.graphics.text_2d(tostring(self.items[i]), constants.vec2.new(tx, ty), constants.FONT_SIZE, col_text, false)
            end
            if hovered and constants.mouse_state.left_clicked then
                self:set(i)
                self.is_open = false
            end
            cy = cy + ih
        end
        -- click outside to close
        if constants.mouse_state.left_clicked then
            local outside_header = not over_header
            local outside_list = not helpers.is_point_in_rect(mouse.x, mouse.y, gx, ly, gw, list_h)
            if outside_header and outside_list then
                self.is_open = false
            end
        end
    end
end

return Combobox


