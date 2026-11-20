-- ============================================================================
-- NSQC4 / TextQuests / Svetofor
-- Тестовый квест. На этом шаге — только регистрация команды.
-- ============================================================================

NSQC4.RegisterModule("quest_svetofor", function()

    NSQC4.TextQuests.RegisterCommand("светофор", "svetofor", function(sender, words, text)
        NSQC4.TextQuests.Say(sender .. " -> svetofor OK")
    end)

end, 300)