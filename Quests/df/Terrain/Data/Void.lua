-- ============================================================================
-- NSQC4 / Quests / df / Terrain / Data / Void
-- Пустота: без текстуры, hardness = 0, непроходима.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local Data = NSQC4.QuestsDfTerrainData
    if not Data then
        print("|cffff0000[NSQC4]|r Terrain/Data/Void: Init.lua не загружен.")
        return
    end

    Data:Register("void", {
        hardness = 0,
        texture  = nil,          -- без текстуры
        textSize = 0,
        color    = { 0.20, 0.20, 0.20 },
    })
end)