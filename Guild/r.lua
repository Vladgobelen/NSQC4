-- ============================================================================
-- NSQC4 / Guild / RakDetector
-- Слушает гильд-чат. Срабатывает, если ОДНОВРЕМЕННО:
--   1) ник отправителя содержит "варлок"
--   2) в тексте сообщения есть "рак"
-- Тогда пишет в гильд-чат "-принизить <Ник отправителя>".
--
-- Модуль: rakdetector
-- ============================================================================

NSQC4.RegisterModule("rakdetector", function()

    NSQC4.ChatCatcher:Register(function(words, sender, text, channel, prefix)
        if channel ~= "GUILD" then return end
        if not sender or sender == "" then return end
        if sender == UnitName("player") then return end

        local nickHasVarlok = sender:lower():find("варлок", 1, true) ~= nil
        local textHasRak    = text and text:lower():find("рак", 1, true) ~= nil

        if nickHasVarlok and textHasRak then
            SendChatMessage("-принизить " .. sender, "GUILD")
        end
    end, "rakdetector")

end)