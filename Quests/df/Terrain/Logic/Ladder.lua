-- ============================================================================
-- NSQC4 / Quests / df / Terrain / Logic / Ladder
-- Логика лестницы: клики — в Actions/Terrain/Ladder.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local Terrain = NSQC4.QuestsDfTerrain
    if not Terrain then return end

    Terrain:RegisterType("ladder", {
        onClick = function(index)
            -- ничего (клики — в Actions)
        end,
        contextMenu = nil,
    })
end)