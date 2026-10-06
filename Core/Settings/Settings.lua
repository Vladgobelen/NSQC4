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

-- ============================================================================
-- Список известных модулей (для UI)
-- ============================================================================
NSQC4.Settings.MODULES = {
        { key = "version_officer",  label = "Версия в офицерский чат",   tooltip = "Отображать в чат верность версии аддона." },
    { key = "course",           label = "Курс Lua",                  tooltip = "Интерактивный курс по Lua: модули, практика, проверка кода, напоминалка." },
    { key = "gp",               label = "ГП / Аукцион / Лут",        tooltip = "Управление ГП: окно со списком, начисление, аукцион, выдача лута с босса, трекер рейда." },
    { key = "promote",          label = "Повышение",                  tooltip = "Команда «-повысить [Ник]» в гильд-чате. Без ника — массовое повышение И.О. Констеблей без заметок." },
    { key = "demote",           label = "Понижение",                  tooltip = "Команда «-принизить Ник» в гильд-чате. Понижает указанного игрока." },
    { key = "kick",             label = "Кик неактивных",             tooltip = "Команда «-кик [Ник]» в гильд-чате. Без ника — массовый кик неактивных по критериям (звание, заметки, офлайн)." },
    { key = "boobs",            label = "Сиськи",                     tooltip = "Реагирует на «покажи сиськи Ник» в гильд-чате. Отправляет случайный ASCII-арт в офицерский чат." },
    { key = "bs_player",        label = "БС игрока",                  tooltip = "Расчёт бонус-скора игрока с учётом спека. Используется для команды «-илвл» и подсказок." },
    { key = "bs_item",          label = "БС предмета",                tooltip = "Показывает бонус-скор предмета в тултипе при наведении." },
    { key = "bs_chat",          label = "Команда -илвл",              tooltip = "Команда «-илвл [Ник]» в гильд-чате. Выводит илвл, ГС, БС и капы в офицерский чат." },
    { key = "itemlevel",        label = "Средний илвл",               tooltip = "Расчёт среднего уровня предметов (ilvl). Используется в БС и тултипе иконки аддона." },
    { key = "ui_mail",          label = "Сбор почты",                 tooltip = "Кнопка «ЗАБРАТЬ ВСЁ» в окне почты — автоматический сбор всех писем одной кнопкой." },
    { key = "ui_chat",          label = "Кнопки чата",                tooltip = "Дополнительные кнопки у чат-фреймов: Общение, Меню, Вниз, Настройки. Цвет текста показывает последний чат." },
    { key = "ui_map",           label = "Управление картой",          tooltip = "ПКМ по крестику карты — перемещение, СКМ — меню масштаба." },
    { key = "ui_ao",            label = "Ссылки АО",                  tooltip = "Кликабельные ники из канала АО. ЛКМ — вставить ник в чат, ПКМ — запросить информацию." },
    { key = "ui_calendar",      label = "Календарь",                  tooltip = "Кнопка «Создать» в форме события и контекстное меню события календаря." },
    { key = "ui_timer",         label = "Таймер",                     tooltip = "Кнопка «T» — таймер с обратным отсчётом и звуковым сигналом. Команда /ns_timer." },
    { key = "ui_list",          label = "Список алертов",             tooltip = "Окно управления списком алертов: ник → звук. СКМ по иконке аддона открывает окно." },
    { key = "ui_vendor",        label = "Быстрая покупка эмблем",     tooltip = "Кнопки быстрой покупки эмблем у вендора (1 / 5 / 10 / 50) справа от окна торговли." },

    -- ui_frames
    { key = "ui_frames_chat",   label = "Фильтр чата",        tooltip = "Фильтрация чата по тексту и каналам. Команда /ns_fc." },
    { key = "ui_frames_layers", label = "Слои",               tooltip = "Изменение слоёв любых фреймов. Можно сделать окновыше ниже остальных. Команда /ns_fclayer." },
    { key = "ui_frames_alpha",  label = "Прозрачность",       tooltip = "Изменение прозрачности любых фреймов. Команда /ns_fcalpha." },
    { key = "ui_frames_move",   label = "Перемещение",        tooltip = "Перемещение любых фреймов. Команда /ns_fcmove." },
}