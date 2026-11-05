-- ============================================================================
-- NSQC4 / Quests / df / Terrain / Data / Tree
-- Базовые характеристики типа "Дерево" (tree).
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local Data = NSQC4.QuestsDfTerrainData
    if not Data then
        print("|cffff0000[NSQC4]|r Terrain/Data/Tree: Init.lua не загружен.")
        return
    end

    local IMG_PATH = "Interface\\AddOns\\NSQC4\\Media\\Images\\"

    Data:Register("tree", {
        hardness = 1500,
        texture  = IMG_PATH .. "00t",
        textSize = 9,
        color    = { 0.45, 0.70, 0.30 },
    })
end)