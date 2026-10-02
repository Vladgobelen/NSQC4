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
    -- ГП / Аукцион / Лут
    { key = "gp",        label = "ГП / Аукцион / Лут" },

    -- Управление гильдией
    { key = "promote",   label = "Повышение" },
    { key = "demote",    label = "Понижение" },
    { key = "kick",      label = "Кик неактивных" },

    -- Развлечения
    { key = "boobs",     label = "Сиськи" },

    -- Бонус-скор
    { key = "bs_player", label = "БС: игрока" },
    { key = "bs_item",   label = "БС: на предметах" },
    { key = "bs_chat",   label = "БС: команда -илвл" },
    { key = "itemlevel", label = "Средний илвл" },

    -- Интерфейс
    { key = "ui_mail",   label = "Интерфейс: сбор почты" },
    { key = "ui_chat",   label = "Интерфейс: кнопки чата" },
    { key = "ui_map",    label = "Интерфейс: управление картой" },
    { key = "ui_ao",     label = "Интерфейс: ссылки АО" },
}