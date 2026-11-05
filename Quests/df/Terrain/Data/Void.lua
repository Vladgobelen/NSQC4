-- ============================================================================
-- NSQC4 / Quests / df / Terrain / Data / Void
-- Пустота: чёрный квадрат. Текстура — стандартная WHITE8x8 (без внешних
-- файлов), затемняется в Terrain/UI/Api через SetVertexColor(0,0,0,1).
-- hardness = 0, непроходима.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local Data = NSQC4.QuestsDfTerrainData
    if not Data then
        print("|cffff0000[NSQC4]|r Terrain/Data/Void: Init.lua не загружен.")
        return
    end

    Data:Register("void", {
        hardness = 0,
        texture  = "Interface\\Buttons\\WHITE8x8",   -- белая заливка, затемняется в UI/Api
        textSize = 0,
        color    = { 0.05, 0.05, 0.05 },
    })
end)