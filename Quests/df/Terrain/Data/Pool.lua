-- ============================================================================
-- NSQC4 / Quests / df / Terrain / Data / Pool
-- Базовые характеристики типа "Бассейн" (pool).
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local Data = NSQC4.QuestsDfTerrainData
    if not Data then
        print("|cffff0000[NSQC4]|r Terrain/Data/Pool: Init.lua не загружен.")
        return
    end

    local IMG_PATH = "Interface\\AddOns\\NSQC4\\Media\\Images\\"

    Data:Register("pool", {
        hardness = 10000,
        texture  = IMG_PATH .. "bas",
        textSize = 9,
        color    = { 0.30, 0.55, 0.85 },
    })
end)