-- ============================================================================
-- NSQC4 / Quests / Field / Core / Instance / Create
-- Одна логика: создание экземпляра поля.
--
-- Вызывается ПОСЛЕ Init.lua (вес 280 → 281), когда QuestsFieldClass
-- уже объявлен.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then
        print("|cffff0000[NSQC4]|r Instance/Create: QuestsFieldClass не создан.")
        return
    end

    NSQC4.Field = QuestsField.new()

end, 281)