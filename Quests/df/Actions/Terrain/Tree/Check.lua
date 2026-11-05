-- ============================================================================
-- NSQC4 / Quests / df / Actions / Terrain / Tree / Check
-- Проверка: tree в клетке?
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local A = NSQC4.QuestsDfTerrainActions
    if not A then
        print("|cffff0000[NSQC4]|r Tree/Check: Init.lua не загружен.")
        return
    end

    A.Types["tree"] = A.Types["tree"] or {}

    A.Types["tree"].Check = function(index)
        index = tonumber(index) or 0
        if index < 1 then return false end

        local Grid = NSQC4.QuestsDfGrid
        if not Grid then return false end

        return Grid:GetTerrain(index) == "tree"
    end

end)