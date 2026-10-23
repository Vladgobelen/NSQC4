-- ============================================================================
-- NSQC4 / Core / Settings / Modifiers
-- ВСЕГДА активен. Не через RegisterModule.
--
-- Публичный API:
--   NSQC4.Modifiers.ShiftDown() / CtrlDown() / AltDown() / AnyDown()
--   NSQC4.Modifiers.CountDown()      -- сколько зажато (0..3)
--   NSQC4.Modifiers.TwoOrMoreDown()  -- true, если зажато ≥ 2
--   NSQC4.Modifiers.CurrentCombo()   -- "shift+ctrl" | "shift+alt" | "ctrl+alt" | "shift+ctrl+alt" | nil
--   NSQC4.Modifiers.OnShiftChanged(fn) / OnCtrlChanged(fn) / OnAltChanged(fn) / OnAnyChanged(fn)
--   NSQC4.Modifiers.OnTwoOrMoreChanged(fn)  -- fn(on, combo)
--   NSQC4.Modifiers.Unregister(fn)
--
-- Внутри — только MODIFIER_STATE_CHANGED (на клиенте IsShiftKeyDown = nil).
-- ============================================================================

NSQC4 = NSQC4 or {}
NSQC4.Modifiers = NSQC4.Modifiers or {}

local M = NSQC4.Modifiers

local state = { shift = false, ctrl = false, alt = false }
local handlers = { shift = {}, ctrl = {}, alt = {}, any = {} }
local twoHandlers = {}

-- ============================================================================
-- Состояние
-- ============================================================================
function M.ShiftDown() return state.shift end
function M.CtrlDown()  return state.ctrl  end
function M.AltDown()   return state.alt   end
function M.AnyDown()   return state.shift or state.ctrl or state.alt end

function M.CountDown()
    local n = 0
    if state.shift then n = n + 1 end
    if state.ctrl  then n = n + 1 end
    if state.alt   then n = n + 1 end
    return n
end

-- true, только если зажато ≥ 2 модификатора
function M.TwoOrMoreDown()
    return M.CountDown() >= 2
end

-- строка комбинации, если зажато ≥ 2, иначе nil
function M.CurrentCombo()
    local s = state.shift
    local c = state.ctrl
    local a = state.alt
    if s and c and a then return "shift+ctrl+alt" end
    if s and c then return "shift+ctrl" end
    if s and a then return "shift+alt" end
    if c and a then return "ctrl+alt" end
    return nil
end

-- ============================================================================
-- Подписки
-- ============================================================================
local function add(kind, fn)
    if type(fn) ~= "function" then return end
    table.insert(handlers[kind], fn)
end

function M.OnShiftChanged(fn) add("shift", fn) end
function M.OnCtrlChanged(fn)  add("ctrl",  fn) end
function M.OnAltChanged(fn)   add("alt",   fn) end
function M.OnAnyChanged(fn)   add("any",   fn) end

function M.OnTwoOrMoreChanged(fn)
    if type(fn) ~= "function" then return end
    table.insert(twoHandlers, fn)
end

function M.Unregister(fn)
    for _, list in pairs(handlers) do
        for i = #list, 1, -1 do
            if list[i] == fn then table.remove(list, i) end
        end
    end
    for i = #twoHandlers, 1, -1 do
        if twoHandlers[i] == fn then table.remove(twoHandlers, i) end
    end
end

-- ============================================================================
-- Рассылка
-- ============================================================================
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

local function fireTwo()
    if #twoHandlers == 0 then return end
    local on = M.TwoOrMoreDown()
    local combo = M.CurrentCombo()
    for _, fn in ipairs(twoHandlers) do
        local ok, err = pcall(fn, on, combo)
        if not ok then
            print("|cffff0000[NSMOD]|r ошибка колбэка two: " .. tostring(err))
        end
    end
end

-- ============================================================================
-- Событие
-- ============================================================================
local ef = CreateFrame("Frame")
ef:RegisterEvent("MODIFIER_STATE_CHANGED")
ef:SetScript("OnEvent", function(_, _, key, value)
    if not key then return end
    local down = (value == 1)

    if key == "LSHIFT" or key == "RSHIFT" then
        local was = state.shift; state.shift = down
        if was ~= down then
            fire("shift", down)
            fire("any", M.AnyDown())
            fireTwo()
        end
    elseif key == "LCTRL" or key == "RCTRL" then
        local was = state.ctrl; state.ctrl = down
        if was ~= down then
            fire("ctrl", down)
            fire("any", M.AnyDown())
            fireTwo()
        end
    elseif key == "LALT" or key == "RALT" then
        local was = state.alt; state.alt = down
        if was ~= down then
            fire("alt", down)
            fire("any", M.AnyDown())
            fireTwo()
        end
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

        local fnTwo = function(on, combo)
            print("|cff00ffff[NSMOD WATCH]|r TWO -> " .. tostring(on)
                .. " combo=" .. tostring(combo))
        end
        M.OnTwoOrMoreChanged(fnTwo)
        table.insert(watchHandlers, fnTwo)

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
        .. " alt=" .. tostring(state.alt)
        .. " count=" .. tostring(M.CountDown())
        .. " two=" .. tostring(M.TwoOrMoreDown())
        .. " combo=" .. tostring(M.CurrentCombo()))
    print("|cff00ffff[NSMOD]|r /nsmod watch | /nsmod watch off")
end