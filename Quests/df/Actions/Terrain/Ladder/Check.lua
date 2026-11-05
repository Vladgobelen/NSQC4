-- ============================================================================
-- NSQC4 / Quests / df / Actions / Terrain / Ladder / Check
-- Проверка: ladder в клетке?
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local A = NSQC4.QuestsDfTerrainActions
    if not A then
        print("|cffff0000[NSQC4]|r Ladder/Check: Init.lua не загружен.")
        return
    end

    A.Types["ladder"] = A.Types["ladder"] or {}

    A.Types["ladder"].Check = function(index)
        index = tonumber(index) or 0
        if index < 1 then return false end
        local Grid = NSQC4.QuestsDfGrid
        if not Grid then return false end
        return Grid:GetTerrain(index) == "ladder"
    end

end)