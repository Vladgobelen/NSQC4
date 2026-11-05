-- ============================================================================
-- NSQC4 / Quests / df / Goblin / Behavior / Init
-- Регистрация поведений гоблина: aggressive, peaceful.
-- Реализации — в соседних файлах (Aggressive.lua, Peaceful.lua).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    NSQC4.QuestsDfGoblin = NSQC4.QuestsDfGoblin or {}
    NSQC4.QuestsDfGoblin.Behavior = NSQC4.QuestsDfGoblin.Behavior or {}

    -- Здесь можно объявлять «что есть» для гоблина, чтобы Tick знал.
    -- Пока — пусто, потому что Peaceful использует Default, а Aggressive — пока не реализован.
    -- Когда появятся конкретные реализации — они сами зарегистрируются через Registry:Register.

end)