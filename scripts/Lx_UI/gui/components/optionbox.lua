local constants = require("gui/utils/constants")
local helpers = require("gui/utils/helpers")

local Optionbox = {}
Optionbox.__index = Optionbox

-- Optionbox: a titled container with vertical auto-scrolling content and collapsible spoiler children
function Optionbox:new(owner_gui, title, x, y, w, h)
	local o = setmetatable({}, Optionbox)
	o.gui = owner_gui
	o.kind = "optionbox"
	o.title = tostring(title or "Optionbox")
	o.x, o.y, o.w, o.h = x or 0, y or 0, w or 240, h or 200
	o.children = {}
	o.scroll_y = 0
	o.content_h = h or 200
	o.header_h = 20
	o.visible_if = nil
	return o
end

function Optionbox:set_visible_if(fn) self.visible_if = fn end
function Optionbox:is_visible() if self.visible_if then return not not self.visible_if(self) end return true end

function Optionbox:_layout_children()
	-- Stack children vertically, honoring each spoiler's expanded height
	local y = self.header_h + 4
	for i = 1, #self.children do
		local ch = self.children[i]
		ch.x = 6
		ch.y = y
		y = y + (ch.h or 0) + 6
	end
	self.content_h = math.max(self.h, y + 4)
end

function Optionbox:add_child(spoiler)
	spoiler.parent = self
	self.children = self.children or {}
	table.insert(self.children, spoiler)
	self:_layout_children()
end

function Optionbox:clear()
    -- Hide any declarative controls created by spoilers before clearing
    if self.children then
        for i = 1, #self.children do
            local ch = self.children[i]
            if ch and ch.dispose_rows then ch:dispose_rows() end
        end
    end
    self.children = {}
    self:_layout_children()
end

function Optionbox:scroll(delta)
	local overflow = math.max(0, (self.content_h or self.h) - self.h)
	local next_y = math.max(0, math.min(self.scroll_y + delta, overflow))
	self.scroll_y = next_y
end

function Optionbox:render()
	if not (self.gui and self.gui.is_open and self:is_visible()) then return end
	if not core.graphics then return end
	local gx, gy = self.gui.x + self.x, self.gui.y + self.y
	-- background & border
	core.graphics.rect_2d_filled(constants.vec2.new(gx, gy), self.w, self.h, constants.color.new(14,18,30,220), 6)
	core.graphics.rect_2d(constants.vec2.new(gx, gy), self.w, self.h, constants.color.new(32,40,70,255), 1, 6)
	-- title bar area
    -- header title
    core.graphics.text_2d(self.title, constants.vec2.new(gx + 8, gy + 2), constants.FONT_SIZE, constants.color.white(235), false)
	-- wheel scrolling when hovered
	if core.input and core.input.get_mouse_wheel then
		local m = constants.mouse_state.position
		if helpers.is_point_in_rect(m.x, m.y, gx, gy, self.w, self.h) then
			local wheel = core.input.get_mouse_wheel()
			if wheel ~= 0 then self:scroll(-wheel * 18) end
		end
	end
    -- clipping (applies to spoilers and their content)
    local clip_x, clip_y = gx, gy + self.header_h
    local clip_w, clip_h = self.w, self.h - self.header_h
    if core.graphics.set_scissor then core.graphics.set_scissor(true, clip_x, clip_y, clip_w, clip_h) end
    -- draw children with vertical offset by scroll_y
    self:_layout_children()
	for i = 1, #self.children do
		local ch = self.children[i]
        if ch.render_at then
            local cx = gx + (ch.x or 0)
            local cy = gy + (ch.y or 0) - (self.scroll_y or 0)
            ch:render_at(cx, cy, self.w - 12)
        end
	end
	if core.graphics.set_scissor then core.graphics.set_scissor(false, 0, 0, 0, 0) end
	-- simple scrollbar
	local overflow = (self.content_h or self.h) - self.h
	if overflow > 1 then
		local bar_w = 6
		local track_x = gx + self.w - bar_w - 4
		local track_y = gy + self.header_h + 4
		local track_h = self.h - self.header_h - 8
		core.graphics.rect_2d_filled(constants.vec2.new(track_x, track_y), bar_w, track_h, constants.color.new(26,32,48,200), 3)
		local ratio = (self.h - self.header_h) / (self.content_h - self.header_h)
		local knob_h = math.max(16, math.floor(track_h * ratio))
		local t = (self.scroll_y or 0) / overflow
		local knob_y = track_y + math.floor((track_h - knob_h) * t)
		core.graphics.rect_2d_filled(constants.vec2.new(track_x, knob_y), bar_w, knob_h, constants.color.new(60,90,160,220), 3)
	end
end

-- Spoiler child element
local Spoiler = {}
Spoiler.__index = Spoiler

function Spoiler:new(title, h_collapsed, h_expanded)
	local o = setmetatable({}, Spoiler)
	o.kind = "spoiler"
	o.title = tostring(title or "Spoiler")
	o.h_collapsed = h_collapsed or 24
	o.h_expanded = h_expanded or 120
	o.is_open = false
	o.children = {}
	o.x, o.y, o.w, o.h = 0, 0, 220, o.h_collapsed
    o._rows = nil
    o._rows_ctx = nil
    o._rows_cache = { color = {}, num2 = {}, combo = {} }
	return o
end

function Spoiler:add_child(comp)
	comp.parent = self
	table.insert(self.children, comp)
end

function Spoiler:toggle()
	self.is_open = not self.is_open
	self.h = self.is_open and self.h_expanded or self.h_collapsed
end

-- Optional declarative rows support for properties rendering
-- rows: array of { type, label, get, set, get_index, set_index, items, visible, style }
-- ctx: { gui }
function Spoiler:set_rows(rows, ctx)
    self._rows = rows
    self._rows_ctx = ctx or {}
end

function Spoiler:dispose_rows()
    local cache = self._rows_cache or {}
    -- Hide color pickers
    if cache.color then
        for _, cp in pairs(cache.color) do
            if cp and cp.set_visible_if then cp:set_visible_if(function() return false end) end
            if cp then cp.is_open = false end
        end
    end
    -- Hide paired inputs
    if cache.num2 then
        for _, pair in pairs(cache.num2) do
            if pair and pair.in1 and pair.in1.set_visible_if then pair.in1:set_visible_if(function() return false end) end
            if pair and pair.in2 and pair.in2.set_visible_if then pair.in2:set_visible_if(function() return false end) end
        end
    end
    -- Hide text inputs
    if cache.text then
        for _, inp in pairs(cache.text) do
            if inp and inp.set_visible_if then inp:set_visible_if(function() return false end) end
        end
    end
    -- Hide combos
    if cache.combo then
        for _, cb in pairs(cache.combo) do
            if cb and cb.set_visible_if then cb:set_visible_if(function() return false end) end
        end
    end
    -- Reset caches and rows
    self._rows_cache = { color = {}, num2 = {}, combo = {}, text = {} }
    self._rows = nil
    self._rows_ctx = nil
end

function Spoiler:measure_rows()
    if not self._rows or not self.is_open then return self.h_collapsed end
    local function row_h(t)
		if t == "color" then return 24
        elseif t == "checkbox" then return 22
        elseif t == "number2" then return 22
		elseif t == "combo" then return 24
		elseif t == "note" then return 16
        elseif t == "separator" then return 14
        else return 22 end
    end
    local h = 6
    for i = 1, #self._rows do
        local r = self._rows[i]
        local vis = (not r.visible) or r.visible()
        if vis then h = h + row_h(r.type) end
    end
    -- header (20) + padding (4) + content + bottom pad (6)
    return 20 + 4 + math.max(0, h) + 4
end

function Spoiler:render_at(abs_x, abs_y, max_w)
	local gx, gy = abs_x, abs_y
	self.w = math.max(0, (max_w or self.w))
	-- Auto-size open spoilers to their rows every frame so parents don't guess
	if self.is_open and self._rows and self.measure_rows then
		self.h_expanded = self:measure_rows()
		self.h = self.h_expanded
	end
	-- header row
	local hdr_h = 20
	local hdr_bg = constants.color.new(20,26,42,235)
	local bd = constants.color.new(32,40,70,255)
	core.graphics.rect_2d_filled(constants.vec2.new(gx, gy), self.w, hdr_h, hdr_bg, 4)
	core.graphics.rect_2d(constants.vec2.new(gx, gy), self.w, self.h, bd, 1, 4)
	-- +/-
	local sign_x, sign_y = gx + 6, gy + 6
	local sign_col = constants.color.white(230)
	core.graphics.line_2d(constants.vec2.new(sign_x, sign_y + 4), constants.vec2.new(sign_x + 8, sign_y + 4), sign_col, 2)
	if not self.is_open then
		core.graphics.line_2d(constants.vec2.new(sign_x + 4, sign_y), constants.vec2.new(sign_x + 4, sign_y + 8), sign_col, 2)
	end
	core.graphics.text_2d(self.title, constants.vec2.new(gx + 20, gy + 2), constants.FONT_SIZE, constants.color.white(235), false)
	-- toggle on click
	local m = constants.mouse_state.position
	if constants.mouse_state.left_clicked and helpers.is_point_in_rect(m.x, m.y, gx, gy, self.w, hdr_h) then
		self:toggle()
	end
	-- content region
	if self.is_open then
		-- If declarative rows are attached, render them instead of child components
		if self._rows and self._rows_ctx and self._rows_ctx.gui then
			local gui = self._rows_ctx.gui
			local inner_w = self.w - 12
			local x = gx + 10
			local y = gy + hdr_h + 4
			local label_col = function() return constants.color.white(230) end
			-- Row render helpers
			local function draw_color(label, get, set, vis_fn)
				local fs, rh = 13, 24
				local ty = y + math.floor((rh - fs) / 2) - 1
				core.graphics.text_2d(label, constants.vec2.new(x, ty), fs, label_col(), false)
				local cache = self._rows_cache.color
				local cp = cache[label]
				if not cp then
					cp = gui:AddColorPicker(x + 100 - gui.x, y - gui.y, inner_w - 120, 20, get(), function(_, c) set(c) end)
					cache[label] = cp
				end
				cp.x = x + 100 - gui.x; cp.y = y - gui.y; cp.w = inner_w - 120
				if cp.set_visible_if then cp:set_visible_if(function() return self.is_open and (not vis_fn or vis_fn()) end) end
				y = y + rh
			end
			local function draw_checkbox(label, get, set, style, vis_fn)
				local fs, rh = 12, 22
				local ty = y + math.floor((rh - fs) / 2) - 1
				core.graphics.text_2d(label, constants.vec2.new(x, ty), fs, label_col(), false)
				if style == "toggle" then
					local track_w, track_h = 34, 16
					local track_x = x + 100
					local track_y = y + math.floor((rh - track_h) / 2)
					local on = not not get()
					local track_col = on and constants.color.new(90,150,230,240) or constants.color.new(40,56,90,220)
					core.graphics.rect_2d_filled(constants.vec2.new(track_x, track_y), track_w, track_h, track_col, 8)
					core.graphics.rect_2d(constants.vec2.new(track_x, track_y), track_w, track_h, constants.color.new(32,40,70,255), 1, 8)
					local knob_d = 14
					local knob_x = on and (track_x + track_w - knob_d - 1) or (track_x + 1)
					local knob_y = track_y + 1
					core.graphics.rect_2d_filled(constants.vec2.new(knob_x, knob_y), knob_d, knob_d, constants.color.white(240), 7)
					if constants.mouse_state.left_clicked then
						local mx, my = constants.mouse_state.position.x, constants.mouse_state.position.y
						if mx >= track_x and mx <= track_x + track_w and my >= track_y and my <= track_y + track_h then set(not on) end
					end
				else
					local cbx0, cby0, cbs0 = x + inner_w - 30, y + math.floor((rh - 12) / 2), 12
					core.graphics.rect_2d(constants.vec2.new(cbx0, cby0), cbs0, cbs0, constants.color.new(32,40,70,255), 1, 2)
					if get() then core.graphics.rect_2d_filled(constants.vec2.new(cbx0 + 2, cby0 + 2), cbs0 - 4, cbs0 - 4, constants.color.new(120,190,255,255), 2) end
					if constants.mouse_state.left_clicked then
						local mx, my = constants.mouse_state.position.x, constants.mouse_state.position.y
						if mx >= cbx0 and mx <= cbx0 + cbs0 and my >= cby0 and my <= cby0 + cbs0 then set(not get()) end
					end
				end
				y = y + rh
			end
			local function draw_number2(label, get, set, vis_fn)
				local fs, rh = 12, 22
				local ty = y + math.floor((rh - fs) / 2) - 1
				core.graphics.text_2d(label, constants.vec2.new(x, ty), fs, label_col(), false)
				local ix = x + 100
				local iw = math.floor((inner_w - 120) / 2)
				local cache = self._rows_cache.num2
				local pair = cache[label] or {}
				if not pair.in1 then
					pair.in1 = gui:AddInput(ix - gui.x, y - gui.y, iw, 18, { multiline = false, text = "" }, function(_, v)
						local a = tonumber(v); local _, b = get(); if a then set(a, b) end
					end)
				end
				if not pair.in2 then
					pair.in2 = gui:AddInput(ix - gui.x + iw + 8, y - gui.y, iw, 18, { multiline = false, text = "" }, function(_, v)
						local b = tonumber(v); local a, _ = get(); if b then set(a, b) end
					end)
				end
				pair.in1:set_visible_if(function() return self.is_open and (not vis_fn or vis_fn()) end)
				pair.in2:set_visible_if(function() return self.is_open and (not vis_fn or vis_fn()) end)
				local a,b = get()
				if not pair.in1.is_focused then pair.in1:set_text(tostring(a or 0)) end
				if not pair.in2.is_focused then pair.in2:set_text(tostring(b or 0)) end
				pair.in1.x = ix - gui.x; pair.in1.y = y - gui.y; pair.in1.w = iw
				pair.in2.x = ix - gui.x + iw + 8; pair.in2.y = y - gui.y; pair.in2.w = iw
				cache[label] = pair
				y = y + rh
			end
			local function draw_text(label, get, set)
				local fs, rh = 12, 22
				local ty = y + math.floor((rh - fs) / 2) - 1
				core.graphics.text_2d(label, constants.vec2.new(x, ty), fs, label_col(), false)
				local ix = x + 100
				local iw = inner_w - 120
				local cache = self._rows_cache
				cache.text = cache.text or {}
				local inp = cache.text[label]
				if not inp then
					inp = gui:AddInput(ix - gui.x, y - gui.y, iw, 18, { multiline = false, text = tostring(get()) }, function(_, v)
						set(v)
					end)
					cache.text[label] = inp
				end
				inp.x = ix - gui.x; inp.y = y - gui.y; inp.w = iw
				if inp.set_visible_if then inp:set_visible_if(function() return self.is_open end) end
				if not inp.is_focused then inp:set_text(tostring(get())) end
				y = y + rh
			end
			local function draw_combo(label, items, get_index, set_index, vis_fn)
				local fs, rh = 12, 22
				local ty = y + math.floor((rh - fs) / 2) - 1
				core.graphics.text_2d(label, constants.vec2.new(x, ty), fs, label_col(), false)
				local cache = self._rows_cache.combo
				local cb = cache[label]
				local idx = get_index()
				local ix = x + 100
				local iw = inner_w - 120
				if not cb then
					cb = gui:AddCombobox(ix - gui.x, y - gui.y + 1, iw, 22, items, idx, function(_, i) set_index(i) end, nil)
					cache[label] = cb
				end
				cb.x = ix - gui.x; cb.y = y - gui.y + 1; cb.w = iw; cb.h = 22
				if cb.set_visible_if then cb:set_visible_if(function() return self.is_open and (not vis_fn or vis_fn()) end) end
				if cb.get_selected_index and cb.set_selected_index and cb:get_selected_index() ~= idx then cb:set_selected_index(idx) end
				y = y + rh
			end
			local function draw_note(text)
				local fs, rh = 10, 14
				local ty = y + math.floor((rh - fs) / 2) - 1
				local col = constants.color.new(200, 210, 230, 200)
				core.graphics.text_2d(text, constants.vec2.new(x, ty), fs, col, false)
				y = y + rh
			end
			for i = 1, #self._rows do
				local r = self._rows[i]
				local vis = (not r.visible) or r.visible()
				if vis then
					local vf = function() return (not r.visible) or r.visible() end
					if r.type == "color" then draw_color(r.label, r.get, r.set, vf)
					elseif r.type == "checkbox" then draw_checkbox(r.label, r.get, r.set, r.style, vf)
					elseif r.type == "number2" then draw_number2(r.label, r.get, r.set, vf)
					elseif r.type == "combo" then draw_combo(r.label, r.items, r.get_index, r.set_index, vf)
					elseif r.type == "text" then draw_text(r.label, r.get, r.set)
					elseif r.type == "note" then draw_note(r.text or r.label or "")
					elseif r.type == "separator" then
						core.graphics.rect_2d(constants.vec2.new(x, y + 4), inner_w - 20, 1, constants.color.new(32,40,70,200), 1, 0)
						y = y + 14
					end
				end
			end
		else
		local cy = gy + hdr_h + 4
		for i = 1, #self.children do
			local ch = self.children[i]
			if ch and ch.render then
				ch:render() -- child components are regular GUI components owned by the same Menu
			end
			cy = cy + (ch and ch.h or 0) + 6
		end
		end
	end
end

return {
	Optionbox = Optionbox,
	Spoiler = Spoiler,
}


