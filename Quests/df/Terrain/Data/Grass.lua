-- ============================================================================
-- NSQC4 / Quests / df / Terrain / Data / Grass
-- Базовые характеристики типа "Трава" (grass).
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local Data = NSQC4.QuestsDfTerrainData
    if not Data then
        print("|cffff0000[NSQC4]|r Terrain/Data/Grass: Init.lua не загружен.")
        return
    end

    local IMG_PATH = "Interface\\AddOns\\NSQC4\\Media\\Images\\"

    Data:Register("grass", {
        hardness = 100,
        texture  = IMG_PATH .. "00f",
        textSize = 9,
        color    = { 0.30, 0.75, 0.30 },
    })
end)