-- ============================================================================
-- NSQC4 / Quests / df / Terrain / Data / Ladder
-- Параметры лестницы.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local Data = NSQC4.QuestsDfTerrainData
    if not Data then
        print("|cffff0000[NSQC4]|r Terrain/Data/Ladder: Init.lua не загружен.")
        return
    end

    local IMG = "Interface\\AddOns\\NSQC4\\Media\\Images\\"

    local DEFAULT_HP_PER_MATERIAL     = 100
    local DEFAULT_RETURN_PER_MATERIAL = 100

    local MATERIALS = {
        wood  = { hpPer = 100, returnPer = 100 },
        stone = { hpPer = 100, returnPer = 100 },
        metal = { hpPer = 100, returnPer = 100 },
        gold  = { hpPer = 100, returnPer = 100 },
    }

    Data:Register("ladder", {
        hardness = 0,
        texture  = IMG .. "00l",
        textSize = 9,
        color    = { 0.85, 0.65, 0.20 },
        tint     = { 1.0, 1.0, 1.0, 1.0 },
        tints    = {
            wood  = { 0.55, 0.35, 0.20, 1 },
            stone = { 0.60, 0.60, 0.60, 1 },
            metal = { 0.80, 0.80, 0.90, 1 },
            gold  = { 1.00, 0.85, 0.10, 1 },
        },

        hpPerMaterial     = DEFAULT_HP_PER_MATERIAL,
        returnPerMaterial = DEFAULT_RETURN_PER_MATERIAL,
        materials         = MATERIALS,
    })

    function Data:GetLadderParams(material)
        local def = self:Get("ladder")
        if not def then
            return DEFAULT_HP_PER_MATERIAL, DEFAULT_RETURN_PER_MATERIAL
        end
        local m = material and def.materials and def.materials[material]
        if m then
            return tonumber(m.hpPer)     or def.hpPerMaterial     or DEFAULT_HP_PER_MATERIAL,
                   tonumber(m.returnPer) or def.returnPerMaterial or DEFAULT_RETURN_PER_MATERIAL
        end
        return tonumber(def.hpPerMaterial)     or DEFAULT_HP_PER_MATERIAL,
               tonumber(def.returnPerMaterial) or DEFAULT_RETURN_PER_MATERIAL
    end
end)