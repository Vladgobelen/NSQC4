-- ============================================================================
-- NSQC4 / Quests / df / Terrain / Data / Stone
-- Базовые характеристики типа "Камень" (stone).
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local Data = NSQC4.QuestsDfTerrainData
    if not Data then
        print("|cffff0000[NSQC4]|r Terrain/Data/Stone: Init.lua не загружен.")
        return
    end

    local IMG_PATH = "Interface\\AddOns\\NSQC4\\Media\\Images\\"

    Data:Register("stone", {
        hardness = 2000,
        texture  = IMG_PATH .. "0ka",
        textSize = 9,
        color    = { 0.60, 0.60, 0.60 },
    })
end)