-- ============================================================================
-- NSQC4 / nowim / Archive
-- Хранилище для старых сообщений (архив)
-- ============================================================================

NSQC4.RegisterModule("nowim", function()
    local C = NSQC4.Nowim.Config
    local S = NSQC4.Nowim.Storage
    local A = {}
    NSQC4.Nowim.Archive = A

    -- Инициализация таблицы архивов
    C.db.archives = C.db.archives or {}

    -- Функция добавления сообщения в архив
    function A.AddToArchive(key, msgData)
        C.db.archives[key] = C.db.archives[key] or {}
        table.insert(C.db.archives[key], msgData)
    end

    -- Функция получения архива
    function A.GetArchive(key)
        return C.db.archives[key] or {}
    end

    -- Функция очистки архива (если понадобится)
    function A.ClearArchive(key)
        if C.db.archives[key] then
            C.db.archives[key] = {}
        end
    end

    -- Слэш-команда для просмотра архива
    SLASH_NOWIM_ARCHIVE1 = "/nowim_archive"
    SlashCmdList["NOWIM_ARCHIVE"] = function(nick)
        nick = (nick or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if nick == "" then
            print("|cffff0000[Nowim]|r Укажите ник: /nowim_archive ИмяНика")
            return
        end

        local messages = A.GetArchive(nick)
        if #messages == 0 then
            print("|cff00ff00[Nowim]|r Архив для " .. nick .. " пуст.")
            return
        end

        print("|cff00ff00[Nowim]|r Архив для " .. nick .. " (" .. #messages .. " сообщений):")
        -- Выводим последние 20 сообщений из архива в чат
        local startIdx = math.max(1, #messages - 20)
        for i = startIdx, #messages do
            local m = messages[i]
            local sender = m.char or "Неизвестно"
            print(string.format("[%s] %s: %s", m.time or "??:??", sender, m.text or ""))
        end
    end
end)