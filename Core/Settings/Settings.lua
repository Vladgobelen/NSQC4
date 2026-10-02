-- ============================================================================
-- NSQC4 / Core / Settings / Settings
-- Логика настроек модулей.
-- Хранение: nsDbc4.settings.disabled[name] = true для ВЫКЛЮЧЕННЫХ.
-- Нет записи = модуль включён.
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

    -- Подтаблица настроек чата
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
        sounds = {},     -- [ник] = путь к звуку (бывший testQ.fls)
    }

    return nsDbc4.settings
end

EnsureSettings()

-- ============================================================================
-- API
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

-- Список известных модулей (для UI)
NSQC4.Settings.MODULES = {
    { key = "gp",             label = "ГП / Аукцион / Лут" },
    { key = "promote",        label = "Повышение" },
    { key = "demote",         label = "Понижение" },
    { key = "kick",           label = "Кик неактивных" },
    { key = "boobs",          label = "Сиськи" },
    { key = "bs_player",      label = "БС: игрока" },
    { key = "bs_item",        label = "БС: на предметах" },
    { key = "bs_chat",        label = "БС: команда -илвл" },
    { key = "itemlevel",      label = "Средний илвл" },
    { key = "ui_mail",        label = "Интерфейс: сбор почты" },
    { key = "ui_chat",        label = "Интерфейс: кнопки чата" },
    { key = "ui_map",         label = "Интерфейс: управление картой" },
    { key = "ui_ao",          label = "Интерфейс: ссылки АО" },
    { key = "ui_calendar",    label = "Интерфейс: календарь" },
    { key = "ui_timer",       label = "Интерфейс: таймер" },
    { key = "ui_list",        label = "Интерфейс: список алертов" },
    { key = "ui_slashpanel",  label = "Интерфейс: панель слэш-команд" },
}