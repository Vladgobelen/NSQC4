-- ============================================================================
-- NSQC4 / Quests / Field / Bootstrap / Init
-- Одна логика: порядок инициализации экземпляра поля.
-- БЕЗ таймеров и OnUpdate. Всё синхронно.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local field = NSQC4.Field
    if not field then
        print("|cffff0000[NSQC4]|r Bootstrap/Init: NSQC4.Field не создан.")
        return
    end

    -- Безопасный вызов метода
    local function call(method, ...)
        if type(field[method]) == "function" then
            local ok, err = pcall(field[method], field, ...)
            if not ok then
                print("|cffff0000[NSQC4]|r Bootstrap/Init:", method, "УПАЛ:", tostring(err))
            end
            return ok
        else
            print("|cffff0000[NSQC4]|r Bootstrap/Init: метод", method, "НЕ ОПРЕДЕЛЁН")
            return false
        end
    end

    -- ========================================================================
    -- Инициализация поля
    -- ========================================================================
    call("Load")
    call("CreateFrame")
    call("CreateCells")
    call("ReflowCells")
    call("InitPanels")

    -- Свитчеры панелей
    call("CreateSwitchers")

    -- Отрисовка API-кнопок
    call("RefreshAllButtons")

    -- Раскладка свитчеров
    call("RefreshSwitchers")

    -- ========================================================================
    -- Ввод (мышь)
    -- ПКМ регистрируется в Border/Click.lua через AddMouseHandler.
    -- ========================================================================
    call("SetupMouse")

    -- ========================================================================
    -- Оформление
    -- ========================================================================
    call("CreateBackdrop")
    call("SetupFrameDrag")
    call("CreateCloseButton")
    call("CreateResizeHandle")

end, 620)