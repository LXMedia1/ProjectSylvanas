local constants = require("gui/utils/constants")
local helpers = require("gui/utils/helpers")
local persist = require("gui/utils/persist")

local ColorPicker = {}
ColorPicker.__index = ColorPicker

-- opts: { show_custom = true }
function ColorPicker:new(owner_gui, x, y, w, h, color, on_change, opts)
    local o = setmetatable({}, ColorPicker)
    o.gui = owner_gui
    o.x = tonumber(x or 0) or 0
    o.y = tonumber(y or 0) or 0
    o.w = tonumber(w or 140) or 140
    o.h = tonumber(h or 24) or 24
    o.on_change = on_change
    o.opts = opts or {}
    local c = color or { r = 255, g = 255, b = 255, a = 255 }
    local cr = tonumber(c.r); if not cr then cr = 255 end
    local cg = tonumber(c.g); if not cg then cg = 255 end
    local cb = tonumber(c.b); if not cb then cb = 255 end
    local ca = tonumber(c.a); if not ca then ca = 255 end
    o.r = math.floor(cr)
    o.g = math.floor(cg)
    o.b = math.floor(cb)
    o.a = math.floor(ca)
    o.is_open = false
    o.custom_colors = persist.load_colors() or {}
    o._pressed_in = false
    return o
end

function ColorPicker:set_visible_if(fn)
    self.visible_if = fn
end

function ColorPicker:is_visible()
    if self.visible_if then return not not self.visible_if(self) end
    return true
end

function ColorPicker:get()
    return { r = self.r, g = self.g, b = self.b, a = self.a }
end

function ColorPicker:set_rgb(r, g, b)
    local rr = tonumber(r); if not rr then rr = 0 end
    local gg = tonumber(g); if not gg then gg = 0 end
    local bb = tonumber(b); if not bb then bb = 0 end
    rr = math.max(0, math.min(255, math.floor(rr)))
    gg = math.max(0, math.min(255, math.floor(gg)))
    bb = math.max(0, math.min(255, math.floor(bb)))
    if rr ~= self.r or gg ~= self.g or bb ~= self.b then
        self.r, self.g, self.b = rr, gg, bb
        if self.on_change then self.on_change(self, self:get()) end
    end
end

function ColorPicker:set_alpha(a)
    local aa = tonumber(a); if not aa then aa = 0 end
    aa = math.max(0, math.min(255, math.floor(aa)))
    if aa ~= self.a then
        self.a = aa
        if self.on_change then self.on_change(self, self:get()) end
    end
end

function ColorPicker:add_custom_color()
    local c = { r = self.r, g = self.g, b = self.b }
    table.insert(self.custom_colors, 1, c)
    if #self.custom_colors > 16 then table.remove(self.custom_colors) end
    persist.save_colors(self.custom_colors)
end

local function draw_checker(x, y, w, h)
    local c1 = constants.color.new(200,200,200,255)
    local c2 = constants.color.new(240,240,240,255)
    local sz = 6
    for yy = y, y + h - 1, sz do
        for xx = x, x + w - 1, sz do
            local even = (math.floor((xx - x)/sz) + math.floor((yy - y)/sz)) % 2 == 0
            if core.graphics.rect_2d_filled then
                core.graphics.rect_2d_filled(constants.vec2.new(xx, yy), math.min(sz, x + w - xx), math.min(sz, y + h - yy), even and c1 or c2, 0)
            end
        end
    end
end

function ColorPicker:render()
    if not (self.gui and self.gui.is_open and self:is_visible()) then return end
    if not core.graphics then return end

    local gx, gy = self.gui.x + self.x, self.gui.y + self.y
    local gw, gh = self.w, self.h
    local mouse = constants.mouse_state.position
    local hovered = helpers.is_point_in_rect(mouse.x, mouse.y, gx, gy, gw, gh)

    -- Button background
    local bd = constants.color.new(18,22,30,220)
    local bg = constants.color.new(30,46,80,220)
    local hover = constants.color.new(50,80,140,235)
    local fill = hovered and hover or bg
    if core.graphics.rect_2d_filled then
        core.graphics.rect_2d_filled(constants.vec2.new(gx, gy), gw, gh, fill, 6)
        core.graphics.rect_2d(constants.vec2.new(gx, gy), gw, gh, bd, 1, 6)
    end
    -- Left swatch with checkerboard + color
    local sw = gh - 6
    local sx = gx + 4
    local sy = gy + 3
    draw_checker(sx, sy, sw, sw)
    if core.graphics.rect_2d_filled then
        local col = constants.color.new(self.r, self.g, self.b, self.a)
        core.graphics.rect_2d_filled(constants.vec2.new(sx, sy), sw, sw, col, 3)
        core.graphics.rect_2d(constants.vec2.new(sx, sy), sw, sw, bd, 1, 3)
    end
    -- Text label like a button
    if core.graphics.text_2d then
        local label = string.format("RGBA(%d,%d,%d,%d)", self.r, self.g, self.b, self.a)
        local fs = (constants.Theme and constants.Theme.font and constants.Theme.font.button) or constants.FONT_SIZE
        local tw = (core.graphics.get_text_width and core.graphics.get_text_width(label, fs, 0)) or 0
        local tx = gx + sw + 8 + math.max(0, math.floor((gw - (sw + 12) - tw) / 2))
        local ty = gy + math.floor((gh - fs) / 2) - 1
        core.graphics.text_2d(label, constants.vec2.new(tx, ty), fs, constants.color.white(240), false)
    end

    if hovered and constants.mouse_state.left_clicked then self._pressed_in = true end
    if self._pressed_in and not constants.mouse_state.left_down then
        self._pressed_in = false
        if hovered then self.is_open = not self.is_open end
    end

    -- Popup
    if not self.is_open then self._popup_abs = nil; return end
    local px = gx
    local py = gy + gh + 4
    local pw = math.max(240, gw)
    local ph = 200
    -- Reposition to avoid spilling off-screen; prefer flipping above if no vertical space
    if core.graphics and core.graphics.get_screen_size then
        local screen = core.graphics.get_screen_size()
        local margin = 20
        -- horizontal clamp with extra breathing room
        if px + pw + margin > screen.x then px = screen.x - pw - margin end
        if px < margin then px = margin end
        -- vertical: flip above if bottom would spill
        if py + ph + margin > screen.y then
            local try_py = gy - ph - 6
            if try_py >= margin then py = try_py else py = screen.y - ph - margin end
        end
    end
    local col_panel = constants.color.new(18,24,40,240)
    local col_border = constants.color.new(18,22,30,255)
    if core.graphics.rect_2d_filled then
        core.graphics.rect_2d_filled(constants.vec2.new(px, py), pw, ph, col_panel, 6)
        core.graphics.rect_2d(constants.vec2.new(px, py), pw, ph, col_border, 1, 6)
    end
    -- Block game clicks under popup
    if constants.hot_zones then table.insert(constants.hot_zones, { x = px, y = py, w = pw, h = ph }) end
    -- Expose popup rect (absolute) for other UIs (e.g., Designer) to ignore input when interacting with the picker
    self._popup_abs = { x = px, y = py, w = pw, h = ph }

    -- Hue bar (vertical)
    local hue_w = 14
    local hue_x = px + 8
    local hue_y = py + 8
    local hue_h = ph - 16
    -- draw as steps
    if core.graphics.rect_2d_filled then
        for i = 0, hue_h - 1 do
            local h = 1.0 - (i / (hue_h - 1))
            local r,g,b = self:_hsv_to_rgb(h, 1, 1)
            core.graphics.rect_2d_filled(constants.vec2.new(hue_x, hue_y + i), hue_w, 1, constants.color.new(r, g, b, 255), 0)
        end
        core.graphics.rect_2d(constants.vec2.new(hue_x, hue_y), hue_w, hue_h, col_border, 1, 2)
    end

    -- SV area
    local sv_x = hue_x + hue_w + 8
    local sv_y = hue_y
    local sv_w = pw - (sv_x - px) - 8 - 16
    local sv_h = hue_h - 36
    -- gradient: overlay white->color and black at bottom
    for i = 0, sv_h - 1 do
        local v = 1.0 - (i / (sv_h - 1))
        for j = 0, sv_w - 1 do
            local s = j / (sv_w - 1)
            local r,g,b = self:_hsv_to_rgb(self._h or 0, s, v)
            if core.graphics.rect_2d_filled then
                core.graphics.rect_2d_filled(constants.vec2.new(sv_x + j, sv_y + i), 1, 1, constants.color.new(r, g, b, 255), 0)
            end
        end
    end
    core.graphics.rect_2d(constants.vec2.new(sv_x, sv_y), sv_w, sv_h, col_border, 1, 2)

    -- RGBA numeric fields (simple +/- buttons)
    local function channel_ctrl(label, cx, cy, value, set_fn)
        local bw, bh = 18, 18
        if core.graphics.text_2d then
            core.graphics.text_2d(label, constants.vec2.new(cx, cy), 12, constants.color.white(230), false)
        end
        cx = cx + 16
        local minus_hov = helpers.is_point_in_rect(mouse.x, mouse.y, cx, cy, bw, bh)
        local plus_hov  = helpers.is_point_in_rect(mouse.x, mouse.y, cx + bw + 40, cy, bw, bh)
        local box_hov   = helpers.is_point_in_rect(mouse.x, mouse.y, cx + bw + 2, cy, 36, bh)
        local bg_btn = constants.color.new(36, 52, 96, 230)
        local bg_hov = constants.color.new(56, 88, 150, 240)
        local bd = constants.color.new(18,22,30,255)
        -- minus
        core.graphics.rect_2d_filled(constants.vec2.new(cx, cy), bw, bh, minus_hov and bg_hov or bg_btn, 3)
        core.graphics.rect_2d(constants.vec2.new(cx, cy), bw, bh, bd, 1, 3)
        -- plus
        core.graphics.rect_2d_filled(constants.vec2.new(cx + bw + 40, cy), bw, bh, plus_hov and bg_hov or bg_btn, 3)
        core.graphics.rect_2d(constants.vec2.new(cx + bw + 40, cy), bw, bh, bd, 1, 3)
        -- value box
        core.graphics.rect_2d_filled(constants.vec2.new(cx + bw + 2, cy), 36, bh, box_hov and bg_hov or bg_btn, 3)
        core.graphics.rect_2d(constants.vec2.new(cx + bw + 2, cy), 36, bh, bd, 1, 3)
        if core.graphics.text_2d then
            local txt = tostring(value)
            local tw = (core.graphics.get_text_width and core.graphics.get_text_width(txt, 12, 0)) or 0
            core.graphics.text_2d(txt, constants.vec2.new(cx + bw + 2 + math.floor((36 - tw)/2), cy + 2), 12, constants.color.white(240), false)
        end
        -- interactions
        if constants.mouse_state.left_clicked then
            if minus_hov then set_fn(value - 1) end
            if plus_hov then set_fn(value + 1) end
        end
    end

    -- Map current RGB to hue for SV
    self._h = self._h or self:_rgb_to_h(self.r, self.g, self.b)
    -- selectors interactions (do not toggle closed while interacting inside)
    if constants.mouse_state.left_down then
        if helpers.is_point_in_rect(mouse.x, mouse.y, hue_x, hue_y, hue_w, hue_h) then
            local rel = math.max(0, math.min(hue_h - 1, mouse.y - hue_y))
            local h = 1.0 - (rel / (hue_h - 1))
            self._h = h
            local s, v = self:_rgb_to_sv(self.r, self.g, self.b)
            local r,g,b = self:_hsv_to_rgb(self._h, s, v)
            self:set_rgb(r, g, b)
        elseif helpers.is_point_in_rect(mouse.x, mouse.y, sv_x, sv_y, sv_w, sv_h) then
            local s = math.max(0, math.min(1, (mouse.x - sv_x) / (sv_w - 1)))
            local v = math.max(0, math.min(1, 1.0 - (mouse.y - sv_y) / (sv_h - 1)))
            local r,g,b = self:_hsv_to_rgb(self._h, s, v)
            self:set_rgb(r, g, b)
        end
    end

    -- Controls area
    local ctrl_y = sv_y + sv_h + 8
    channel_ctrl("R", sv_x, ctrl_y, self.r, function(v) self:set_rgb(v, self.g, self.b) end)
    channel_ctrl("G", sv_x + 90, ctrl_y, self.g, function(v) self:set_rgb(self.r, v, self.b) end)
    channel_ctrl("B", sv_x + 180, ctrl_y, self.b, function(v) self:set_rgb(self.r, self.g, v) end)
    channel_ctrl("A", sv_x + 270, ctrl_y, self.a, function(v) self:set_alpha(v) end)

    -- Custom colors row
    if self.opts.show_custom ~= false then
        local row_y = ctrl_y + 26
        if core.graphics.text_2d then
            core.graphics.text_2d("Custom:", constants.vec2.new(sv_x, row_y), 12, constants.color.white(230), false)
        end
        local cx = sv_x + 56
        local size = 14
        for i = 1, math.min(16, #self.custom_colors) do
            local c = self.custom_colors[i]
            local hov = helpers.is_point_in_rect(mouse.x, mouse.y, cx, row_y - 2, size, size)
            draw_checker(cx, row_y - 2, size, size)
            core.graphics.rect_2d_filled(constants.vec2.new(cx, row_y - 2), size, size, constants.color.new(c.r, c.g, c.b, c.a or 255), 2)
            core.graphics.rect_2d(constants.vec2.new(cx, row_y - 2), size, size, constants.color.new(18,22,30,255), 1, 2)
            if hov and constants.mouse_state.left_clicked then
                self:set_rgb(c.r, c.g, c.b)
                self:set_alpha(c.a or 255)
            end
            cx = cx + size + 4
        end
        -- Add button
        local add_x = cx + 8
        local bw, bh = 46, 18
        local add_hov = helpers.is_point_in_rect(mouse.x, mouse.y, add_x, row_y - 2, bw, bh)
        local bg_btn = constants.color.new(36, 52, 96, 230)
        local bg_hov = constants.color.new(56, 88, 150, 240)
        core.graphics.rect_2d_filled(constants.vec2.new(add_x, row_y - 2), bw, bh, add_hov and bg_hov or bg_btn, 3)
        core.graphics.rect_2d(constants.vec2.new(add_x, row_y - 2), bw, bh, constants.color.new(18,22,30,255), 1, 3)
        if core.graphics.text_2d then
            core.graphics.text_2d("Add", constants.vec2.new(add_x + 10, row_y), 12, constants.color.white(240), false)
        end
        if add_hov and constants.mouse_state.left_clicked then
            self:add_custom_color()
        end
    end

    -- Close popup on Enter/Escape or outside click only (not while dragging inside)
    local VK_RETURN = 0x0D
    local VK_ESCAPE = 0x1B
    if (core.input and core.input.is_key_pressed and (core.input.is_key_pressed(VK_RETURN) or core.input.is_key_pressed(VK_ESCAPE))) then
        self.is_open = false
    end
    if constants.mouse_state.left_clicked and not helpers.is_point_in_rect(mouse.x, mouse.y, px, py, pw, ph) and not hovered then
        self.is_open = false
    end
end

-- Utilities: color conversions (0..1 HSV)
function ColorPicker:_hsv_to_rgb(h, s, v)
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    local r_, g_, b_ = 0, 0, 0
    local m = i % 6
    if m == 0 then r_, g_, b_ = v, t, p
    elseif m == 1 then r_, g_, b_ = q, v, p
    elseif m == 2 then r_, g_, b_ = p, v, t
    elseif m == 3 then r_, g_, b_ = p, q, v
    elseif m == 4 then r_, g_, b_ = t, p, v
    else r_, g_, b_ = v, p, q end
    return math.floor(r_ * 255 + 0.5), math.floor(g_ * 255 + 0.5), math.floor(b_ * 255 + 0.5)
end

function ColorPicker:_rgb_to_h(r, g, b)
    r = r / 255; g = g / 255; b = b / 255
    local mx = math.max(r, g, b)
    local mn = math.min(r, g, b)
    local d = mx - mn
    if d == 0 then return 0 end
    local h
    if mx == r then h = ((g - b) / d) % 6
    elseif mx == g then h = ((b - r) / d) + 2
    else h = ((r - g) / d) + 4 end
    h = h / 6
    if h < 0 then h = h + 1 end
    return h
end

function ColorPicker:_rgb_to_sv(r, g, b)
    r = r / 255; g = g / 255; b = b / 255
    local mx = math.max(r, g, b)
    local mn = math.min(r, g, b)
    local v = mx
    local s = (mx == 0) and 0 or (mx - mn) / mx
    return s, v
end

return ColorPicker


