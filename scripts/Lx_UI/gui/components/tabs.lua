local constants = require("gui/utils/constants")

local Tabs = {}
Tabs.__index = Tabs

-- Simple tab bar component: horizontal row under header
-- Usage:
--   local tabs = gui:AddTabs({ {id="General", label="General"}, {id="Advanced", label="Advanced"} })
--   tabs:set_active("General")
--   if tabs:is_active("Advanced") then ... end

function Tabs:new(owner_gui, items, y_offset)
    local o = setmetatable({}, Tabs)
    o.gui = owner_gui
    o.items = {}
    for i = 1, #(items or {}) do
        local it = items[i]
        table.insert(o.items, { id = tostring(it.id or ("tab"..i)), label = tostring(it.label or it.id or ("Tab "..i)) })
    end
    o.active_id = (o.items[1] and o.items[1].id) or nil
    o.y_offset = y_offset or (constants.HEADER_HEIGHT + 6)
    o.height = 24
    return o
end

function Tabs:set_active(id)
    self.active_id = id
end

function Tabs:is_active(id)
    return self.active_id == id
end

function Tabs:get_height()
    return (self.height or 24) + 6 -- include strip padding
end

-- Returns content origin in LOCAL gui coordinates (not including gui.x/gui.y)
function Tabs:get_content_origin()
    local x = 8 + 10 -- strip_x left (8) + default inner margin (10)
    local y = (self.y_offset or (constants.HEADER_HEIGHT + 6)) + self:get_height() + 10 -- default top margin
    return x, y
end

-- Returns available inner size below the tab strip, in LOCAL coordinates
function Tabs:get_content_size()
    local cx, cy = self:get_content_origin()
    local w = math.max(0, (self.gui.width or 0) - cx - 8)
    local h = math.max(0, (self.gui.height or 0) - cy - 8)
    return w, h
end

function Tabs:render()
    if not (self.gui and self.gui.is_open and core.graphics and core.graphics.get_text_width) then return end
    local strip_x = self.gui.x + 8
    local strip_y = self.gui.y + (self.y_offset or (constants.HEADER_HEIGHT + 6))
    local strip_w = math.max(0, (self.gui.width or 0) - 16)
    local tab_h = self.height or 24
    local spacing = 2
    local pad_x = 12
    local shoulder = 12

    local col_strip_bg = constants.color.new(18, 24, 40, 160)
    local col_divider = constants.color.new(14, 18, 26, 220)
    local col_tab_inactive = constants.color.new(44, 64, 110, 190)
    local col_tab_hover = constants.color.new(68, 98, 160, 220)
    local col_tab_active = constants.color.new(205, 215, 235, 240)
    local col_text = constants.color.white(255)
    local col_text_inactive = constants.color.new(230, 235, 245, 235)
    local col_text_active = constants.color.new(30, 40, 60, 255)
    local col_top_highlight = constants.color.new(255, 255, 255, 22)
    local col_edge = constants.color.new(16, 22, 30, 230)

    -- strip background (flat)
    if core.graphics.rect_2d_filled then
        core.graphics.rect_2d_filled(constants.vec2.new(strip_x, strip_y), strip_w, tab_h + 6, col_strip_bg, 0)
    end

    local mouse = constants.mouse_state.position
    local clicked_index = nil
    local draw_x = strip_x + 8
    local active_index = nil
    local tab_geoms = {}

    -- Measure and store geometries first
    for i = 1, #self.items do
        local label = self.items[i].label
        local tw = core.graphics.get_text_width(label, constants.FONT_SIZE, 0)
        local w = tw + pad_x * 2 + shoulder * 2
        local is_active = (self.active_id == self.items[i].id)
        local ty = strip_y + 2
        tab_geoms[i] = { x = draw_x, y = ty, w = w, h = tab_h, label = label, active = is_active }
        if is_active then active_index = i end
        draw_x = draw_x + w + spacing
    end

    -- Helper: draw a single trapezoid tab as two filled triangles for seamless edges
    local function draw_tab(g, color)
        -- Draw middle rectangle first
        local rx = g.x + shoulder
        local rw = g.w - shoulder * 2
        if core.graphics.rect_2d_filled then
            core.graphics.rect_2d_filled(constants.vec2.new(rx, g.y), rw, g.h, color, 0)
        end
        -- Fill two side wedges without overlapping the rectangle (prevents alpha seams)
        if core.graphics.triangle_2d_filled then
            -- left wedge
            core.graphics.triangle_2d_filled(
                constants.vec2.new(g.x, g.y + g.h),
                constants.vec2.new(rx, g.y),
                constants.vec2.new(rx, g.y + g.h),
                color
            )
            -- right wedge
            local rx2 = rx + rw
            core.graphics.triangle_2d_filled(
                constants.vec2.new(g.x + g.w, g.y + g.h),
                constants.vec2.new(rx2, g.y),
                constants.vec2.new(rx2, g.y + g.h),
                color
            )
        end
    end

    -- Draw inactive tabs first
    for i = 1, #tab_geoms do
        if i ~= active_index then
            local g = tab_geoms[i]
            local hovered = (mouse.x >= g.x and mouse.x <= g.x + g.w and mouse.y >= g.y and mouse.y <= g.y + g.h)
            local fill = hovered and col_tab_hover or col_tab_inactive
            draw_tab(g, fill)
            if core.graphics.text_2d then
                local text_x = g.x + shoulder + pad_x
            local fs = (constants.Theme and constants.Theme.font and constants.Theme.font.tab) or constants.FONT_SIZE
            local text_y = g.y + math.floor((g.h - fs) / 2) - 1
            core.graphics.text_2d(g.label, constants.vec2.new(text_x, text_y), fs, col_text_inactive, false)
            end
            if hovered and constants.mouse_state.left_clicked then clicked_index = i end
            self.items[i]._rect = { x = g.x, y = g.y, w = g.w, h = g.h }
        end
    end

    -- Draw active tab on top
    if active_index then
        local g = tab_geoms[active_index]
        draw_tab(g, col_tab_active)
        -- top inner highlight for active (disabled to avoid tone differences)
        if core.graphics.text_2d then
            local text_x = g.x + shoulder + pad_x
            local fs = (constants.Theme and constants.Theme.font and constants.Theme.font.tab) or constants.FONT_SIZE
            local text_y = g.y + math.floor((g.h - fs) / 2) - 1
            core.graphics.text_2d(g.label, constants.vec2.new(text_x, text_y), fs, col_text_active, false)
        end
        if (mouse.x >= g.x and mouse.x <= g.x + g.w and mouse.y >= g.y and mouse.y <= g.y + g.h) and constants.mouse_state.left_clicked then
            clicked_index = active_index
        end
        self.items[active_index]._rect = { x = g.x, y = g.y, w = g.w, h = g.h }
    end

    -- separators between tabs (subtle)
    if core.graphics.rect_2d then
        for i = 1, #tab_geoms - 1 do
            local a = tab_geoms[i]
            local b = tab_geoms[i + 1]
            local sx = a.x + a.w + math.floor(spacing / 2)
            core.graphics.rect_2d(constants.vec2.new(sx, strip_y + 4), 1, tab_h - 2, col_divider, 1, 0)
        end
    end

    -- bottom divider across strip, with gap under active tab base (attached look)
    if core.graphics.rect_2d then
        local y = strip_y + (self.height or 24) + 4
        if active_index then
            local g = tab_geoms[active_index]
            local gap_left = g.x
            if gap_left > strip_x then
                core.graphics.rect_2d(constants.vec2.new(strip_x, y), gap_left - strip_x, 1, col_divider, 1, 0)
            end
            local gap_right_x = g.x + g.w
            local right_w = (strip_x + strip_w) - gap_right_x
            if right_w > 0 then
                core.graphics.rect_2d(constants.vec2.new(gap_right_x, y), right_w, 1, col_divider, 1, 0)
            end
        else
            core.graphics.rect_2d(constants.vec2.new(strip_x, y), strip_w, 1, col_divider, 1, 0)
        end
    end

    if clicked_index then
        self.active_id = self.items[clicked_index].id
    end
end

return Tabs


