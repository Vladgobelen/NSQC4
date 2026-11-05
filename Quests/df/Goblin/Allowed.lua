-- ============================================================================
-- NSQC4 / Quests / df / Goblin / Allowed
-- С какими объектами ландшафта умеет работать гоблин.
-- Пока — все текущие: земля, камень, трава, дерево, бассейн.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    NSQC4.QuestsDfGoblin = NSQC4.QuestsDfGoblin or {}
    NSQC4.QuestsDfGoblin.Allowed = {
        earth  = true,
        stone  = true,
        grass  = true,
        tree   = true,
        pool   = true,
    }
end)