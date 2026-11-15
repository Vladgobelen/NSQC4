-- ============================================================================
-- NSQC4 / Quests / Field / Settings / Radio
-- Один раздел окна настроек: радиогруппа видимости кнопки настроек.
--
-- Порядок в окне — ТОЛЬКО по индексу (LayoutWindow сортирует по нему):
--   4) Лейбл «Настройки кнопок» (CENTER)
--   5) Лейбл-подпись «Кнопка "Настройки":» (CENTER)
--   6) RadioGroup «settingsVisibility» (CENTER, HORIZONTAL):
--        1 — Видима всегда
--        2 — При прозрачной панели (borderVisible = false)
--        3 — При непрозрачной панели (borderVisible = true)
--
-- Значение синхронизируется с NSDB:buttons → "LEFT:1:1" → opts.visible.
-- При смене — RefreshAllButtons().
--
-- Синхронизация при открытии окна — через W:RegisterOnShow (491),
-- БЕЗ перехвата W.Show / W.Toggle.
-- ============================================================================
NSQC4.RegisterModule("quests", function()
    local W    = NSQC4.FieldWindow
    local NSDB = NSQC4.NSDB
    if not W or not NSDB then return end

    local field = NSQC4.Field
    if not field then return end

    local KEY = "LEFT:1:1"

    local function GetMode()
        local data = NSDB:Get("buttons", KEY)
        if data and data.opts and data.opts.visible then
            return data.opts.visible
        end
        return 1
    end

    local function SetMode(value)
        local data = NSDB:Get("buttons", KEY)
        if not data then return end
        data.opts = data.opts or {}
        data.opts.visible = value
        NSDB:Set("buttons", KEY, data)
        if field.RefreshAllButtons then field:RefreshAllButtons() end
    end

    local function Sync()
        if not W["settings"] then return end

        if W.EnsureRadioGroup then
            W:EnsureRadioGroup("settings", "settingsVisibility")
        end
        if W.LayoutWindow then
            W:LayoutWindow("settings")
        end

        W:SetRadioValue("settings", "settingsVisibility", GetMode())
    end

    -- 4) Заголовок раздела
    W:RegisterLabel("settings", 4, "Настройки кнопок", nil, { align = "CENTER" })

    -- 5) Подпись
    W:RegisterLabel("settings", 5, 'Кнопка "Настройки":', nil, { align = "CENTER" })

    -- 6) Радиогруппа — три значения, текст в tooltip
    W:RegisterRadioGroup(
        "settings", 6,
        "settingsVisibility",
        {
            { value = 1, tooltip = "Видима всегда" },
            { value = 2, tooltip = "При прозрачной панели" },
            { value = 3, tooltip = "При непрозрачной панели" },
        },
        SetMode,
        { align = "CENTER", direction = "HORIZONTAL" }
    )

    -- Если окно уже создано — синхронизировать сразу.
    if W["settings"] then Sync() end

    -- Иначе — отложить до создания окна.
    if W.RegisterOnShow then
        W:RegisterOnShow("settings", Sync)
    end
end, 590)