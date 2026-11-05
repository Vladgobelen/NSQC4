-- ============================================================================
-- NSQC4 / Quests / df / Dwarf / Init
-- Точка входа модуля Дворфов.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    -- Создаем пространство имен для дворфов
    NSQC4.QuestsDfDwarf = NSQC4.QuestsDfDwarf or {}

    -- Регистрируем тип в глобальном реестре модулей df
    NSQC4.QuestsDfModules = NSQC4.QuestsDfModules or {}
    NSQC4.QuestsDfModules["dwarf"] = NSQC4.QuestsDfModules["dwarf"] or {
        label   = "Дворфы",
        order   = 120,
        enabled = true,
    }

    -- Таблица для хранения скриптов поведения
    NSQC4.QuestsDfDwarf.Behavior = {}

    print("|cff00ffff[DWF-DEBUG]|r Модуль Dwarf инициализирован.")

end)