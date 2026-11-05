-- ============================================================================
-- NSQC4 / Quests / df / Transform / Data
-- Таблица преобразований и лута по типам ландшафта.
--
-- def:
--   drop        — id дропа ("earth"|"wood"|"stone"|"herb"|nil)
--   dropIcon    — иконка дропа
--   dropMin     — минимум дропов
--   dropMax     — максимум дропов
--   dropTarget  — "self" | "neighbors"
--                 (если nextTerrain == "void", всегда "neighbors")
--   nextTerrain — во что превращается клетка ("earth"|"void")
--   eject       — вытолкнуть существо (для void — да)
--
-- Лут кладётся в лут-якоря (все 9, кроме TOPLEFT).
-- Если свободных лут-якорей нет — дроп не кладётся.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Transform = NSQC4.QuestsDfTransform
    if not Transform then
        print("|cffff0000[NSQC4]|r Transform/Data: Init.lua не загружен.")
        return
    end

    local IMG = "Interface\\AddOns\\NSQC4\\Media\\Images\\"

    -- tree → 1 wood в эту клетку, клетка → earth
    Transform:Register("tree", {
        drop        = "wood",
        dropIcon    = IMG .. "00t",
        dropMin     = 1,
        dropMax     = 1,
        dropTarget  = "self",
        nextTerrain = "earth",
        eject       = false,
    })

    -- stone → 2..5 stone в эту клетку, клетка → earth
    Transform:Register("stone", {
        drop        = "stone",
        dropIcon    = IMG .. "0ka",
        dropMin     = 2,
        dropMax     = 5,
        dropTarget  = "self",
        nextTerrain = "earth",
        eject       = false,
    })

    -- grass → 1..3 herb в эту клетку, клетка → earth
    Transform:Register("grass", {
        drop        = "herb",
        dropIcon    = IMG .. "00f",
        dropMin     = 1,
        dropMax     = 3,
        dropTarget  = "self",
        nextTerrain = "earth",
        eject       = false,
    })

    -- earth → 1 earth в соседние (50/50 на каждого), клетка → void
    Transform:Register("earth", {
        drop        = "earth",
        dropIcon    = IMG .. "00z",
        dropMin     = 1,
        dropMax     = 1,
        dropTarget  = "neighbors",
        nextTerrain = "void",
        eject       = true,
    })

    -- pool → 1..2 stone в соседние, клетка → void
    Transform:Register("pool", {
        drop        = "stone",
        dropIcon    = IMG .. "0ka",
        dropMin     = 1,
        dropMax     = 2,
        dropTarget  = "neighbors",
        nextTerrain = "void",
        eject       = true,
    })

    -- ladder → 0..1 wood в соседние, клетка → void
    Transform:Register("ladder", {
        drop        = "wood",
        dropIcon    = IMG .. "00t",
        dropMin     = 0,
        dropMax     = 1,
        dropTarget  = "neighbors",
        nextTerrain = "void",
        eject       = false,
    })

    print("|cff00ffff[TRANSFORM]|r Transform/Data загружен (" .. #Transform:GetAll() .. " типов).")

end)