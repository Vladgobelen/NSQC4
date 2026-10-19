-- ============================================================================
-- NSQC4 / Core / Settings / Settings
-- Логика настроек модулей.
-- Хранение: nsDbc4.settings.disabled[name] = true для ВЫКЛЮЧЕННЫХ.
-- Нет записи = модуль включён.
--
-- Список модулей для UI строится ДИНАМИЧЕСКИ из NSQC4.ModuleMeta,
-- который заполняется в NSQC4.RegisterModule(key, fn, meta).
-- Статический MODULES больше не нужен — используйте GetModules().
-- ============================================================================

NSQC4 = NSQC4 or {}
NSQC4.Settings = NSQC4.Settings or {}

-- ============================================================================
-- Инициализация структуры
-- ============================================================================
local function EnsureSettings()
    nsDbc4 = nsDbc4 or {}
    nsDbc4.settings = nsDbc4.settings or {}
    nsDbc4.settings.disabled = nsDbc4.settings.disabled or {}

    -- Подтаблица настроек чата (кнопки чат-фреймов)
    nsDbc4.settings.chat = nsDbc4.settings.chat or {
        showChatColor = true,
        openGuildChat = false,
    }

    -- Подтаблица настроек таймера / listUI
    nsDbc4.settings.timer = nsDbc4.settings.timer or {
        time = 0,
        visible = true,
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = 0,
        sounds = {},     -- [ник] = путь к звуку
    }

    -- Подтаблицы модулей ui_frames
    nsDbc4.settings.framesChat = nsDbc4.settings.framesChat or {
        filters = {},
        captureDelay = 5,
    }

    nsDbc4.settings.framesLayers = nsDbc4.settings.framesLayers or {
        layers = {},
        layersOriginal = {},
        captureDelay = 5,
    }

    nsDbc4.settings.framesAlpha = nsDbc4.settings.framesAlpha or {
        frames = {},
        captureDelay = 5,
    }

    nsDbc4.settings.framesMove = nsDbc4.settings.framesMove or {
        frames = {},
        captureDelay = 5,
    }

    -- ========================================================================
    -- Подтаблицы курса Lua (ключ "course")
    -- Лежат рядом с settings, потому что это данные модуля, а не настройки.
    -- ========================================================================
    nsDbc4.course = nsDbc4.course or {}
    nsDbc4.course.ui = nsDbc4.course.ui or {}
    nsDbc4.course.logic = nsDbc4.course.logic or {}
    nsDbc4.course.reminder = nsDbc4.course.reminder or {}

    return nsDbc4.settings
end

EnsureSettings()

-- ============================================================================
-- API: включённость
-- ============================================================================

-- Модуль включён, если для него НЕТ записи в disabled
function NSQC4.Settings.IsModuleEnabled(name)
    local s = EnsureSettings()
    return not s.disabled[name]
end

-- Установить состояние: включён — стираем запись, выключен — пишем
function NSQC4.Settings.SetModuleEnabled(name, enabled)
    local s = EnsureSettings()
    if enabled then
        s.disabled[name] = nil
    else
        s.disabled[name] = true
    end
end

-- ============================================================================
-- API: список модулей для UI
-- ============================================================================

-- Возвращает актуальный отсортированный список модулей (без hidden).
-- Каждый элемент: { key, label, tooltip, order, hidden }.
-- Источник — NSQC4.ModuleMeta (заполняется автоматически в RegisterModule).
function NSQC4.Settings.GetModules()
    local list = {}
    for _, m in pairs(NSQC4.ModuleMeta or {}) do
        if not m.hidden then
            list[#list + 1] = m
        end
    end
    table.sort(list, function(a, b)
        local oa = a.order or 1000
        local ob = b.order or 1000
        if oa ~= ob then return oa < ob end
        return a.key < b.key
    end)
    return list
end

-- Обратная совместимость: старый код мог читать NSQC4.Settings.MODULES.
-- Отдаём прокси-таблицу, которая всегда возвращает актуальный список.
setmetatable(NSQC4.Settings, {
    __index = function(t, k)
        if k == "MODULES" then
            return NSQC4.Settings.GetModules()
        end
        return nil
    end,
})