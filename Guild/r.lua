-- ============================================================================
-- NSQC4 / Guild / RakDetector
-- Слушает гильд-чат. Срабатывает, если в тексте сообщения есть "шефрак"
-- в любой раскладке (рус/лат).
-- Тогда пишет в гильд-чат:
--   -принизить <Ник отправителя>
--   -репутация <Ник отправителя> -1000
--
-- Модуль: rakdetector
-- ============================================================================

NSQC4.RegisterModule("rakdetector", function()

    -- Возвращает true, если в тексте встречается "шефрак" в любой раскладке.
    -- Ловим три варианта: русский, латинский "shefrak", латинский "hefrak".
    local function ContainsShefrak(text)
        if not text or text == "" then return false end
        local low = text:lower()
        if low:find("шефрак", 1, true)  then return true end
        if low:find("shefrak", 1, true) then return true end
        if low:find("hefrak", 1, true)  then return true end
        return false
    end

    NSQC4.ChatCatcher:Register(function(words, sender, text, channel, prefix)
        if channel ~= "GUILD" then return end
        if not sender or sender == "" then return end
        if sender == UnitName("player") then return end

        if ContainsShefrak(text) then
            SendChatMessage("-принизить " .. sender, "GUILD")
            SendChatMessage("-репутация " .. sender .. " -1000", "GUILD")
        end
    end, "rakdetector")

end)