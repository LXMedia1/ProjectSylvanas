local persist = require("gui/utils/persist")

-- Simple keyboard layout mapper. Supports common US/DE mappings including AltGr.
-- Returns printable glyphs for given VK and modifier state, or nil if not handled.

local M = {}

-- Helper to read preferred layout from plugin cfg; defaults to "de" for EU users
local function get_layout_name()
  local ok, cfg = pcall(persist.load_plugin)
  local layout = (ok and cfg and cfg.keyboard_layout) or "de"
  layout = tostring(layout):lower()
  if layout ~= "us" and layout ~= "de" then layout = "de" end
  return layout
end

-- VK constants used here
local VK_0, VK_9 = 0x30, 0x39
local VK_A, VK_Z = 0x41, 0x5A
local VK_SPACE, VK_TAB = 0x20, 0x09
-- OEM keys
local VK_OEM_1   = 0xBA -- US: ;:
local VK_OEM_PLUS= 0xBB -- US: =+
local VK_OEM_COM = 0xBC -- ,<
local VK_OEM_MIN = 0xBD -- -_
local VK_OEM_PER = 0xBE -- .>
local VK_OEM_2   = 0xBF -- /?
local VK_OEM_3   = 0xC0 -- `~
local VK_OEM_4   = 0xDB -- [{
local VK_OEM_5   = 0xDC -- \|
local VK_OEM_6   = 0xDD -- ]}
local VK_OEM_7   = 0xDE -- '"
local VK_OEM_102 = 0xE2 -- <>|

local layouts = {
  us = {
    digit_base  = { [0] = "0","1","2","3","4","5","6","7","8","9" },
    digit_shift = { [0] = ")","!","@","#","$","%","^","&","*","(" },
    digit_altgr = {},
    oem = function(vk, shift, altgr)
      if vk == VK_OEM_1   then return shift and ":" or ";" end
      if vk == VK_OEM_PLUS then return shift and "+" or "=" end
      if vk == VK_OEM_COM then return shift and "<" or "," end
      if vk == VK_OEM_MIN then return shift and "_" or "-" end
      if vk == VK_OEM_PER then return shift and ">" or "." end
      if vk == VK_OEM_2   then return shift and "?" or "/" end
      if vk == VK_OEM_3   then return shift and "~" or "`" end
      if vk == VK_OEM_4   then return shift and "{" or "[" end
      if vk == VK_OEM_5   then return shift and "|" or "\\" end
      if vk == VK_OEM_6   then return shift and "}" or "]" end
      if vk == VK_OEM_7   then return shift and '"' or "'" end
      return nil
    end
  },
  de = {
    -- German T1 main row: 0..9 with Shift/AltGr
    -- Base digits are the same visually, but Shift produces different symbols
    digit_base  = { [0] = "0","1","2","3","4","5","6","7","8","9" },
    -- Shifted: 0..9 -> = ! " § $ % & / ( )
    digit_shift = { [0] = "=","!","\"","§","$","%","&","/","(",")" },
    -- AltGr (Ctrl+Alt): 7 {, 8 [, 9 ], 0 }
    digit_altgr = { [7] = "{", [8] = "[", [9] = "]", [0] = "}" },
    oem = function(vk, shift, altgr)
      -- German OEM approximations using VK_OEM codes
      if vk == VK_OEM_102 then
        if altgr then return "|" end
        return shift and ">" or "<"
      end
      if vk == VK_OEM_1   then return shift and "Ö" or "ö" end
      if vk == VK_OEM_PLUS then return shift and "*" or "+" end
      if vk == VK_OEM_COM then return shift and ";" or "," end
      if vk == VK_OEM_MIN then return shift and "_" or "-" end
      if vk == VK_OEM_PER then return shift and ":" or "." end
      if vk == VK_OEM_2   then return shift and "'" or "#" end
      if vk == VK_OEM_3   then return shift and "°" or "^" end
      if vk == VK_OEM_4   then return shift and "Ä" or "ä" end
      if vk == VK_OEM_5   then return shift and "|" or "\\" end
      if vk == VK_OEM_6   then return shift and "Ü" or "ü" end
      if vk == VK_OEM_7   then return shift and "`" or "'" end
      return nil
    end
  }
}

-- Resolve printable character for vk+modifiers using current layout
function M.resolve(vk, isShift, isCtrl, isAlt)
  if vk == VK_SPACE then return " " end
  if vk == VK_TAB then return "\t" end
  local altgr = (isCtrl and isAlt) or false
  local name = get_layout_name()
  local L = layouts[name] or layouts.de

  -- A-Z
  if vk >= VK_A and vk <= VK_Z then
    local base = string.char(vk)
    if not isShift then base = string.lower(base) end
    return base
  end
  -- 0-9
  if vk >= VK_0 and vk <= VK_9 then
    local d = vk - VK_0
    if altgr and L.digit_altgr[d] then return L.digit_altgr[d] end
    if isShift and L.digit_shift[d] then return L.digit_shift[d] end
    return L.digit_base[d]
  end
  -- OEM
  local oem = L.oem(vk, isShift, altgr)
  if oem then return oem end
  return nil
end

return M


