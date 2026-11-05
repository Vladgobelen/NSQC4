-- ============================================================================
-- NSQC4 / Quests / df / Terrain / Data / Water
-- Базовые характеристики типа "Вода" (water).
--
-- Глубина — не здесь, а в клетке (cell.depth, 1..10). Этот файл задаёт
-- только «паспорт» типа: текстура, цвет, размер текста, hardness.
--
-- hardness = 0: воду не «копают» работой по hardness — у неё своя логика
-- (работу назначим заглушкой в Actions/Terrain/Water).
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local Data = NSQC4.QuestsDfTerrainData
    if not Data then
        print("|cffff0000[NSQC4]|r Terrain/Data/Water: Init.lua не загружен.")
        return
    end

    local IMG_PATH = "Interface\\AddOns\\NSQC4\\Media\\Images\\"

    Data:Register("water", {
        hardness = 0,
        texture  = IMG_PATH .. "00w",
        textSize = 9,
        color    = { 0.30, 0.55, 0.85 },
    })
end)