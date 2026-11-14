-- ============================================================================
-- NSQC4 / Quests / Field / Border / Click
-- Одна логика: ПКМ по frame → ToggleBorderVisible().
--
-- Регистрация — через единый регистратор мыши поля
-- (Field/Frame/Mouse.lua → AddMouseHandler).
--
-- ВАЖНО: вес 395 > 390 (Frame/Mouse.lua), иначе AddMouseHandler ещё не создан.
--
-- ОТЛАДКА: [CLICK]. Отключить — CLICK_DEBUG = false.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local CLICK_DEBUG = true
    local function dbg(...)
        if CLICK_DEBUG then print("|cffffaa00[CLICK]|r", ...) end
    end

    local field = NSQC4.Field
    if not field then
        print("|cffff0000[CLICK]|r NSQC4.Field == nil — обработчик не зарегистрирован")
        return
    end

    if type(field.AddMouseHandler) ~= "function" then
        print("|cffff0000[CLICK]|r field:AddMouseHandler == nil — Frame/Mouse.lua не загружен?")
        return
    end

    dbg("Регистрирую обработчик ПКМ через AddMouseHandler")

    field:AddMouseHandler(function(x, y, button, event)
        dbg(string.format("handler: event=%s button=%s x=%s y=%s",
            tostring(event), tostring(button),
            tostring(x), tostring(y)))

        if event ~= "down" then return false end
        if button ~= "RightButton" then return false end

        dbg("ПКМ down — вызываю ToggleBorderVisible")

        if type(field.ToggleBorderVisible) ~= "function" then
            print("|cffff0000[CLICK]|r field:ToggleBorderVisible == nil — Border/Visible.lua не загружен?")
            return false
        end

        local before = field:IsBorderVisible()
        field:ToggleBorderVisible()
        local after = field:IsBorderVisible()

        dbg(string.format("borderVisible: %s → %s", tostring(before), tostring(after)))

        return true
    end)

    dbg("Обработчик зарегистрирован. Всего обработчиков:",
        field._mouseHandlers and #field._mouseHandlers or "nil")

    if field._mouseHandlers then
        for i, fn in ipairs(field._mouseHandlers) do
            dbg(string.format("  handler[%d] = %s", i, tostring(fn)))
        end
    end

end, 395)