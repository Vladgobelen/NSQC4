-- ============================================================================
-- NSQC4 / Quests / Field / Bootstrap / SlashPanel
-- Одна логика: регистрация кнопки «Квесты» на слэш-панели.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    if NSQC4.SlashPanel_RegisterSectionButton then
        NSQC4.SlashPanel_RegisterSectionButton(
            "Квесты", "П", "/ns_field",
            {
                { text = "Поле квестов 10×10", r = 1.00, g = 0.82, b = 0.00 },
            }
        )
    else
        print("|cffff0000[NSQC4]|r Bootstrap/SlashPanel: NSQC4.SlashPanel_RegisterSectionButton == nil")
    end

end, 622)