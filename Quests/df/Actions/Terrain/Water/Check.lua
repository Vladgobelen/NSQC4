-- ============================================================================
-- NSQC4 / Quests / df / Actions / Terrain / Water / Check
-- Проверка: water в клетке?
--
-- По образцу Earth/Check.lua, Grass/Check.lua, Stone/Check.lua,
-- Tree/Check.lua, Pool/Check.lua.
--
-- Вода — тип ландшафта "water". Глубина (1..10) в этой проверке не участвует:
-- Check отвечает только на вопрос «это вода?», а не «какая глубина?».
-- Глубина берётся отдельно через Grid:GetDepth(index) там, где нужна.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local A = NSQC4.QuestsDfTerrainActions
    if not A then
        print("|cffff0000[NSQC4]|r Water/Check: Init.lua не загружен.")
        return
    end

    A.Types["water"] = A.Types["water"] or {}

    A.Types["water"].Check = function(index)
        index = tonumber(index) or 0
        if index < 1 then return false end

        local Grid = NSQC4.QuestsDfGrid
        if not Grid then return false end

        return Grid:GetTerrain(index) == "water"
    end

end)