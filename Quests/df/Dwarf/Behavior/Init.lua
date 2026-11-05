-- ============================================================================
-- NSQC4 / Quests / df / Dwarf / Behavior / Init
-- Регистрация поведений дворфа: aggressive, peaceful.
-- Реализации — в соседних файлах (Aggressive.lua, Peaceful.lua).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    NSQC4.QuestsDfDwarf = NSQC4.QuestsDfDwarf or {}
    NSQC4.QuestsDfDwarf.Behavior = NSQC4.QuestsDfDwarf.Behavior or {}

    -- Пока — пусто. Peaceful использует Default, Aggressive не реализован.
    -- Конкретные реализации сами зарегистрируются через Registry:Register.

end)