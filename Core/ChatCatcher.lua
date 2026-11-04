-- ============================================================================
-- NSQC4 / Core / ChatCatcher
-- Слушает CHAT_MSG_GUILD, CHAT_MSG_OFFICER и вызывает все зарегистрированные функции.
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
frame:RegisterEvent("CHAT_MSG_OFFICER")
frame:SetScript("OnEvent", function(self, event, text, sender)
    if not text or text == "" then return end

    -- Разбиваем на слова
    local words = {}
    for w in text:gmatch("%S+") do
        table.insert(words, w)
    end

    -- Определяем реальный канал (GUILD или OFFICER)
    local channel = event:match("^CHAT_MSG_(.+)$")

    -- ИСКЛЮЧЕНИЕ: Пропускаем "-гп" дальше (если это именно наша команда)
    local isGpCmd = false
    local lowerText = text:lower()
    local startPos = lowerText:find("-гп", 1, true)
    if startPos then
        -- Проверяем, что это не просто "-гпавно" или "-гп..." — должно быть слово
        local after = lowerText:sub(startPos + #"-гп")
        if after == "" or after:sub(1, 1):match("%s") then
            isGpCmd = true
        end
    end

    -- Если это команда и это НЕ "-гп" — игнорируем (это делает ChatHandler)
    if text:sub(1, 1) == "-" and not isGpCmd then 
        return 
    end

    -- Вызываем всех подписчиков
    for _, entry in ipairs(handlers) do
        if not entry.module or NSQC4.Settings.IsModuleEnabled(entry.module) then
            entry.func(words, sender, text, channel, nil)
        end
    end
end)