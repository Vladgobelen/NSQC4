-- ============================================================================
-- NSQC4 / Core / ChatCatcher
-- Слушает CHAT_MSG_GUILD и вызывает все зарегистрированные функции.
-- Каждая функция сама решает, её это сообщение или нет.
-- ============================================================================

NSQC4 = NSQC4 or {}
NSQC4.ChatCatcher = NSQC4.ChatCatcher or {}

-- Список подписчиков
local handlers = {}

-- ============================================================================
-- Регистрация
-- ============================================================================
function NSQC4.ChatCatcher:Register(func, module)
    table.insert(handlers, { func = func, module = module })
end

-- ============================================================================
-- Фрейм-слушатель
-- ============================================================================
local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_GUILD")
frame:SetScript("OnEvent", function(self, event, text, sender)
    if not text or text == "" then return end

    -- Разбиваем на слова
    local words = {}
    for w in text:gmatch("%S+") do
        table.insert(words, w)
    end

    -- Общая проверка на "-" — это команды, их обрабатывает ChatHandler
    if text:sub(1, 1) == "-" then return end

    -- Вызываем всех подписчиков
    for _, entry in ipairs(handlers) do
        if not entry.module or NSQC4.Settings.IsModuleEnabled(entry.module) then
            entry.func(words, sender, text, "GUILD", nil)
        end
    end
end)