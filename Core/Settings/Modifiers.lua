-- ============================================================================
-- NSQC4 / Core / Settings / Modifiers
-- ВСЕГДА активен. Не через RegisterModule.
-- Публичный API:
--   NSQC4.Modifiers.ShiftDown() / CtrlDown() / AltDown() / AnyDown()
--   NSQC4.Modifiers.OnShiftChanged(fn) / OnCtrlChanged(fn) / OnAltChanged(fn) / OnAnyChanged(fn)
--   NSQC4.Modifiers.Unregister(fn)
--
-- Внутри — только MODIFIER_STATE_CHANGED (на клиенте IsShiftKeyDown = nil).
-- ============================================================================

NSQC4 = NSQC4 or {}
NSQC4.Modifiers = NSQC4.Modifiers or {}

local M = NSQC4.Modifiers

local state = { shift = false, ctrl = false, alt = false }
local handlers = { shift = {}, ctrl = {}, alt = {}, any = {} }

function M.ShiftDown() return state.shift end
function M.CtrlDown()  return state.ctrl  end
function M.AltDown()   return state.alt   end
function M.AnyDown()   return state.shift or state.ctrl or state.alt end

local function add(kind, fn)
    if type(fn) ~= "function" then return end
    table.insert(handlers[kind], fn)
end

function M.OnShiftChanged(fn) add("shift", fn) end
function M.OnCtrlChanged(fn)  add("ctrl",  fn) end
function M.OnAltChanged(fn)   add("alt",   fn) end
function M.OnAnyChanged(fn)   add("any",   fn) end

function M.Unregister(fn)
    for _, list in pairs(handlers) do
        for i = #list, 1, -1 do
            if list[i] == fn then table.remove(list, i) end
        end
    end
end

local function fire(kind, down)
    local list = handlers[kind]
    if not list then return end
    for _, fn in ipairs(list) do
        local ok, err = pcall(fn, down)
        if not ok then
            print("|cffff0000[NSMOD]|r ошибка колбэка: " .. tostring(err))
        end
    end
end

local ef = CreateFrame("Frame")
ef:RegisterEvent("MODIFIER_STATE_CHANGED")
ef:SetScript("OnEvent", function(_, _, key, value)
    if not key then return end
    local down = (value == 1)

    if key == "LSHIFT" or key == "RSHIFT" then
        local was = state.shift; state.shift = down
        if was ~= down then fire("shift", down); fire("any", M.AnyDown()) end
    elseif key == "LCTRL" or key == "RCTRL" then
        local was = state.ctrl; state.ctrl = down
        if was ~= down then fire("ctrl", down); fire("any", M.AnyDown()) end
    elseif key == "LALT" or key == "RALT" then
        local was = state.alt; state.alt = down
        if was ~= down then fire("alt", down); fire("any", M.AnyDown()) end
    end
end)

-- ============================================================================
-- Отладка: /nsmod watch | /nsmod watch off | /nsmod
-- ============================================================================
local watchOn = false
local watchHandlers = {}

SLASH_NSMOD1 = "/nsmod"
SlashCmdList["NSMOD"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")

    if msg == "watch" then
        if watchOn then print("|cff00ffff[NSMOD]|r уже ON") return end
        watchOn = true
        local function mk(name)
            local fn = function(down)
                print("|cff00ffff[NSMOD WATCH]|r " .. name .. " -> " .. tostring(down))
            end
            M["On" .. name .. "Changed"](fn)
            table.insert(watchHandlers, fn)
        end
        mk("Shift"); mk("Ctrl"); mk("Alt"); mk("Any")
        print("|cff00ffff[NSMOD]|r watch ON")
        return
    end
    if msg == "watch off" then
        for _, fn in ipairs(watchHandlers) do M.Unregister(fn) end
        watchHandlers = {}
        watchOn = false
        print("|cffff0000[NSMOD]|r watch OFF")
        return
    end

    print("|cff00ffff[NSMOD]|r state: shift=" .. tostring(state.shift)
        .. " ctrl=" .. tostring(state.ctrl)
        .. " alt=" .. tostring(state.alt))
    print("|cff00ffff[NSMOD]|r /nsmod watch | /nsmod watch off")
end