-- ============================================================================
-- NSQC4 / Quests / Field / Bootstrap
-- Одна логика: порядок инициализации экземпляра поля + слэш /ns_field.
-- Грузится ПОСЛЕДНИМ в блоке Field/*.
--
-- БЕЗ таймеров и OnUpdate. Всё синхронно.
-- ОТЛАДКА: [BOOT]. Отключить — BOOT_DEBUG = false.
-- ============================================================================
NSQC4.RegisterModule("quests", function()
    local BOOT_DEBUG = false
    local function dbg(...)
        if BOOT_DEBUG then print("|cffffaa00[BOOT]|r", ...) end
    end

    local field = NSQC4.Field
    if not field then
        print("|cffff0000[NSQC4]|r Field/Bootstrap: NSQC4.Field не создан.")
        return
    end

    dbg("Старт. field=", tostring(field))

    -- ========================================================================
    -- Безопасный вызов метода: если метода нет — пишем в чат и идём дальше.
    -- ========================================================================
    local function call(method, ...)
        if type(field[method]) == "function" then
            dbg("call:", method)
            local ok, err = pcall(field[method], field, ...)
            if not ok then
                print("|cffff0000[NSQC4]|r Bootstrap:", method, "УПАЛ:", tostring(err))
            end
            return ok
        else
            print("|cffff0000[NSQC4]|r Bootstrap: метод", method, "НЕ ОПРЕДЕЛЁН (файл не загружен?)")
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

    -- 1) Свитчеры панелей
    call("CreateSwitchers")

    -- 2) Отрисовка API-кнопок
    call("RefreshAllButtons")

    -- 3) Раскладка свитчеров
    call("RefreshSwitchers")

    -- ========================================================================
    -- Ввод
    -- ========================================================================
    call("SetupMouse")
    call("SetupFrameClick")

    -- ========================================================================
    -- Оформление
    -- ========================================================================
    call("CreateBackdrop")
    call("SetupFrameDrag")
    call("CreateCloseButton")
    call("CreateResizeHandle")

    -- ========================================================================
    -- Слэш /ns_field
    -- ========================================================================
    SLASH_NSFIELD1 = "/ns_field"
    SlashCmdList["NSFIELD"] = function()
        local f = NSQC4.Field
        if f and f.Toggle then f:Toggle() end
    end
    dbg("Слэш /ns_field зарегистрирован")

    -- ========================================================================
    -- SlashPanel
    -- ========================================================================
    if NSQC4.SlashPanel_RegisterSectionButton then
        dbg("SlashPanel_RegisterSectionButton есть — регистрирую кнопку «Квесты»")
        NSQC4.SlashPanel_RegisterSectionButton(
            "Квесты", "П", "/ns_field",
            {
                { text = "Поле квестов 10×10", r = 1.00, g = 0.82, b = 0.00 },
            }
        )
    else
        print("|cffff0000[NSQC4]|r Bootstrap: NSQC4.SlashPanel_RegisterSectionButton == nil — кнопка на слэш-панели НЕ зарегистрирована")
    end

    -- ========================================================================
    -- Итоговая диагностика: что в итоге создано
    -- ========================================================================
    dbg("=== ИТОГ ===")
    dbg("frame:", tostring(field.frame))
    dbg("_switchers:", field._switchers and #field._switchers or "nil")
    dbg("_panelButtons:", field._panelButtons and "есть" or "nil")
    dbg("_mouseHandlers:", field._mouseHandlers and #field._mouseHandlers or "nil")

    if field._switchers then
        for i, rec in ipairs(field._switchers) do
            dbg(string.format("  switcher[%d] side=%s shown=%s",
                i, tostring(rec.side),
                tostring(rec.texture and rec.texture:IsShown())))
        end
    end

    print("|cff00ffff[FIELD]|r Блок 4 загружен (панели). /ns_field")
end, 630)