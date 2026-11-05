-- ============================================================================
-- NSQC4 / Quests / df / Terrain / Data / Earth
-- Базовые характеристики типа "Земля" (earth).
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local Data = NSQC4.QuestsDfTerrainData
    if not Data then
        print("|cffff0000[NSQC4]|r Terrain/Data/Earth: Init.lua не загружен.")
        return
    end

    local IMG_PATH = "Interface\\AddOns\\NSQC4\\Media\\Images\\"

    Data:Register("earth", {
        hardness = 1000,
        texture  = IMG_PATH .. "00z",
        textSize = 9,
        color    = { 0.85, 0.85, 0.85 },
    })
end)