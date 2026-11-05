-- ============================================================================
-- NSQC4 / Quests / df / Dwarf / Allowed
-- С какими объектами ландшафта умеет работать дворф.
-- Пока — все текущие: земля, камень, трава, дерево, бассейн.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    NSQC4.QuestsDfDwarf = NSQC4.QuestsDfDwarf or {}
    NSQC4.QuestsDfDwarf.Allowed = {
        earth  = true,
        stone  = true,
        grass  = true,
        tree   = true,
        pool   = true,
    }
end)