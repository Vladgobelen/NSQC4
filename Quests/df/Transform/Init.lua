-- ============================================================================
-- NSQC4 / Quests / df / Transform / Init
-- Реестр преобразований + Apply (раздача лута, смена terrain, выталкивание).
--
-- Apply(index, terrainId):
--   1. Определить def по terrainId.
--   2. Раздать лут:
--        - dropTarget == "neighbors" ИЛИ nextTerrain == "void"
--            → 4 соседа (Grid:Neighbors), на каждого 50/50
--              (для pool/ladder — сначала math.random(min,max) дропов,
--               потом каждый раздаётся по соседям 50/50)
--        - dropTarget == "self"
--            → math.random(min,max) дропов в свободные лут-якоря этой клетки
--   3. Сменить terrain на nextTerrain.
--   4. Если nextTerrain == "void" или def.eject — вытолкнуть существо.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Transform = {}
    NSQC4.QuestsDfTransform = Transform

    local byTerrain = {}
    local order     = {}

    function Transform:Register(terrainId, def)
        if type(terrainId) ~= "string" or terrainId == "" then return false end
        if type(def) ~= "table" then return false end
        if not byTerrain[terrainId] then
            order[#order + 1] = terrainId
        end
        def.id = terrainId
        byTerrain[terrainId] = def
        return true
    end

    function Transform:Get(terrainId)
        if type(terrainId) ~= "string" or terrainId == "" then return nil end
        return byTerrain[terrainId]
    end

    function Transform:GetAll()
        local list = {}
        for _, id in ipairs(order) do
            if byTerrain[id] then list[#list + 1] = byTerrain[id] end
        end
        return list
    end

    -- ========================================================================
    -- Раздать лут в эту клетку (dropTarget == "self")
    -- ========================================================================
    local function DropSelf(index, def)
        if not def.drop or not def.dropIcon then return 0 end
        local Drops = NSQC4.QuestsDfTransformDrops
        if not Drops then return 0 end
        local minN = tonumber(def.dropMin) or 1
        local maxN = tonumber(def.dropMax) or minN
        if minN < 0 then minN = 0 end
        if maxN < minN then maxN = minN end
        local n = math.random(minN, maxN)
        local placed = 0
        for _ = 1, n do
            local a = Drops:Add(index, def.drop, def.dropIcon)
            if not a then break end
            placed = placed + 1
        end
        return placed
    end

    -- ========================================================================
    -- Раздать лут по соседям (dropTarget == "neighbors" или nextTerrain == "void")
    --   Для каждого дропа (их math.random(min,max)):
    --     пройти по 4 соседям, на каждого 50/50; если выпало и есть свободный
    --     лут-якорь — положить. Один дроп кладётся в одного соседа.
    --   Если ни один сосед не подошёл — дроп пропадает.
    -- ========================================================================
    local function DropNeighbors(index, def)
        if not def.drop or not def.dropIcon then return 0 end
        local Drops = NSQC4.QuestsDfTransformDrops
        local Grid  = NSQC4.QuestsDfGrid
        if not Drops or not Grid then return 0 end

        local minN = tonumber(def.dropMin) or 1
        local maxN = tonumber(def.dropMax) or minN
        if minN < 0 then minN = 0 end
        if maxN < minN then maxN = minN end
        local total = math.random(minN, maxN)
        if total <= 0 then return 0 end

        local neighbors = Grid:Neighbors(index)
        local placed = 0

        for _ = 1, total do
            -- на каждого соседа 50/50; выбираем первого, кто «выпал» и имеет место
            local chosen = nil
            local shuffled = {}
            for i = 1, #neighbors do shuffled[i] = neighbors[i] end
            -- перемешать
            for i = #shuffled, 2, -1 do
                local j = math.random(i)
                shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
            end
            for _, n in ipairs(shuffled) do
                if math.random() < 0.5 then
                    -- есть ли свободный лут-якорь
                    local free = Drops:FreeAnchors(n)
                    if #free > 0 then
                        chosen = n
                        break
                    end
                end
            end
            if chosen then
                local a = Drops:Add(chosen, def.drop, def.dropIcon)
                if a then placed = placed + 1 end
            end
        end
        return placed
    end

    -- ========================================================================
    -- Вытолкнуть существо из клетки в случайную соседнюю проходимую
    -- ========================================================================
    local function EjectEntity(index)
        local Grid = NSQC4.QuestsDfGrid
        if not Grid then return false end
        local entity = Grid:GetEntity(index)
        if not entity then return false end

        local neighbors = Grid:Neighbors(index)
        local candidates = {}
        for _, n in ipairs(neighbors) do
            local c = Grid:GetCell(n)
            if c and c.terrain ~= "void" and not c.entityName then
                candidates[#candidates + 1] = n
            end
        end
        if #candidates == 0 then return false end

        local target = candidates[math.random(#candidates)]
        Grid:SetEntityName(index, nil)
        Grid:SetEntityName(target, entity.opts and entity.opts.name)
        entity.index = target

        local TerrainApi = NSQC4.QuestsDfTerrainUIApi
        if TerrainApi and TerrainApi.RenderCellFromStorage then
            TerrainApi:RenderCellFromStorage(index)
            TerrainApi:RenderCellFromStorage(target)
        end
        return true
    end

    -- ========================================================================
    -- Apply
    -- ========================================================================
    function Transform:Apply(index, terrainId)
        index = tonumber(index) or 0
        if index < 1 then return false end

        local def = self:Get(terrainId)
        if not def then return false end

        local Terrain = NSQC4.QuestsDfTerrain
        if not Terrain then return false end

        -- 1. Лут
        local isVoidNext = (def.nextTerrain == "void")
        local target = def.dropTarget or "self"
        if isVoidNext then target = "neighbors" end

        if def.drop then
            if target == "neighbors" then
                DropNeighbors(index, def)
            else
                DropSelf(index, def)
            end
        end

        -- 2. Смена terrain
        if def.nextTerrain then
            Terrain:SetTerrain(index, def.nextTerrain)
        end

        -- 3. Выталкивание
        if isVoidNext or def.eject then
            EjectEntity(index)
        end

        return true
    end

end)