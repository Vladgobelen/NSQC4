-- ============================================================================
-- NSQC4 / TextQuests / Core / Registry
-- Хранилище команд текстовых квестов.
-- Одна функциональность: регистрация и поиск команд.
-- ============================================================================

NSQC4 = NSQC4 or {}
NSQC4.TextQuests = NSQC4.TextQuests or {}

-- cmd (lower) -> { questId = ..., handler = ... }
NSQC4.TextQuests.Commands = NSQC4.TextQuests.Commands or {}

-- ============================================================================
-- Регистрация команды.
--   cmd     — строка без ведущего "-", регистр не важен
--   questId — идентификатор квеста (строка)
--   handler — function(sender, words, text)
-- Возвращает true при успехе, false если команда уже занята.
-- ============================================================================
function NSQC4.TextQuests.RegisterCommand(cmd, questId, handler)
    if type(cmd) ~= "string" or cmd == "" then return false end
    if type(handler) ~= "function" then return false end

    cmd = cmd:lower()

    if NSQC4.TextQuests.Commands[cmd] then
        return false
    end

    NSQC4.TextQuests.Commands[cmd] = {
        questId = questId,
        handler = handler,
    }

    -- Сразу вешаем ключ в ChatHandler. Router объявлен в Engine.lua,
    -- который грузится раньше любого файла квеста (см. .toc).
    if NSQC4.ChatHandler and NSQC4.ChatHandler.Register then
        NSQC4.ChatHandler:Register("GUILD:-" .. cmd, {
            func = NSQC4.TextQuests.Router,
            stopOnMatch = true,
        })
    end

    return true
end

-- ============================================================================
-- Поиск команды.
-- ============================================================================
function NSQC4.TextQuests.GetCommand(cmd)
    if type(cmd) ~= "string" then return nil end
    return NSQC4.TextQuests.Commands[cmd:lower()]
end