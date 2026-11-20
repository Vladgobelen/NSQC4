-- ============================================================================
-- NSQC4 / TextQuests / Core / Engine
-- Модуль text_quests: роутер команд.
-- Одна функциональность: принять команду из чата и вызвать её handler.
-- ============================================================================

NSQC4 = NSQC4 or {}
NSQC4.TextQuests = NSQC4.TextQuests or {}

-- ============================================================================
-- Роутер. Регистрируется в ChatHandler на каждый ключ "GUILD:-<cmd>".
--   words  — таблица слов сообщения
--   sender — ник отправителя
--   text   — исходный текст
-- ============================================================================
function NSQC4.TextQuests.Router(words, sender, text, channel, prefix)
    if not words or not words[1] then return end

    local first = words[1]:lower()
    if first:sub(1, 1) ~= "-" then return end

    local cmd = first:sub(2)
    if cmd == "" then return end

    local rec = NSQC4.TextQuests.GetCommand(cmd)
    if not rec then return end

    local ok, err = pcall(rec.handler, sender, words, text)
    if not ok then
        NSQC4.TextQuests.Say("Ошибка команды '" .. cmd .. "': " .. tostring(err))
    end
end

-- ============================================================================
-- Модуль. На этом шаге init пустой: команды регистрируют себя сами
-- (RegisterCommand сразу вешает ключ в ChatHandler).
-- Модуль нужен, чтобы движок был виден в общем реестре модулей
-- и в диагностике MODULE_DEBUG.
-- ============================================================================
NSQC4.RegisterModule("text_quests", function()
    -- intentionally empty
end, 200)