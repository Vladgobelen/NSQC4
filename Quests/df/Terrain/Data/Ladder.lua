-- ============================================================================
-- NSQC4 / Quests / df / Terrain / Data / Ladder
-- Лестница: ставится на void, hardness = 0 (не добывается работой).
-- Используется для переключения этажей (см. Floors/Switch).
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local Data = NSQC4.QuestsDfTerrainData
    if not Data then
        print("|cffff0000[NSQC4]|r Terrain/Data/Ladder: Init.lua не загружен.")
        return
    end

    local IMG = "Interface\\AddOns\\NSQC4\\Media\\Images\\"

    Data:Register("ladder", {
        hardness = 0,
        texture  = IMG .. "ladder",
        textSize = 9,
        color    = { 0.85, 0.65, 0.20 },
    })
end)