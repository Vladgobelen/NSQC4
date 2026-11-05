-- ============================================================================
-- NSQC4 / Quests / df / Terrain / Data / Init
-- Реестр базовых характеристик типов ландшафта.
--
-- Каждый тип — отдельный файл в df/Terrain/Data/:
--   Earth.lua, Grass.lua, Stone.lua, Tree.lua, Pool.lua
--
-- Файл типа зовёт:
--   NSQC4.QuestsDfTerrainData:Register("earth", {
--       hardness = 1000,
--       texture  = "Interface\\AddOns\\NSQC4\\Media\\Images\\00z",
--       textSize = 9,
--       color    = { 0.85, 0.85, 0.85 },
--   })
--
-- API:
--   Data:Register(id, def)  — зарегистрировать
--   Data:Get(id)            — def | nil
--   Data:GetAll()           — таблица id → def
--   Data:Count()            — число
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Data = {}
    NSQC4.QuestsDfTerrainData = Data

    local byId = {}
    local order = {}

    function Data:Register(id, def)
        if type(id) ~= "string" or id == "" then return false end
        if type(def) ~= "table" then return false end

        if not byId[id] then
            order[#order + 1] = id
        end

        def.id = id
        byId[id] = def
        return true
    end

    function Data:Get(id)
        if type(id) ~= "string" or id == "" then return nil end
        return byId[id]
    end

    function Data:GetAll()
        return byId
    end

    function Data:Count()
        return #order
    end

end)