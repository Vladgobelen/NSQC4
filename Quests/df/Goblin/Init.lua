-- ============================================================================
-- NSQC4 / Quests / df / Goblin / Init
-- Точка входа модуля Гоблинов.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    -- Создаем пространство имен для гоблинов
    NSQC4.QuestsDfGoblin = NSQC4.QuestsDfGoblin or {}

    -- Регистрируем тип в глобальном реестре модулей df
    NSQC4.QuestsDfModules = NSQC4.QuestsDfModules or {}
    NSQC4.QuestsDfModules["goblin"] = NSQC4.QuestsDfModules["goblin"] or {
        label   = "Гоблины",
        order   = 110, -- Порядок загрузки (например, до дворфов)
        enabled = true,
    }

    -- Таблица для хранения скриптов поведения
    NSQC4.QuestsDfGoblin.Behavior = {}

    print("|cff00ffff[GOB-DEBUG]|r Модуль Goblin инициализирован.")

end)