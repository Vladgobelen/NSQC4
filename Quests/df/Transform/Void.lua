-- ============================================================================
-- NSQC4 / Quests / df / Transform / Void
-- Пустота: выталкивание существа, проверка, подсчёт.
--
-- Void:IsVoid(index)          → true, если клетка void
-- Void:EjectEntity(index)     → вытолкнуть существо в случайную соседнюю
--                               не-void клетку без существа
-- Void:CountVoid()            → сколько void-клеток на текущем этаже
-- Void:CountTotal()           → всего клеток (COLS*ROWS)
-- Void:PercentVoid()          → доля void (0..1) на текущем этаже
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Void = {}
    NSQC4.QuestsDfTransformVoid = Void

    local Grid = NSQC4.QuestsDfGrid
    if not Grid then
        print("|cffff0000[NSQC4]|r Transform/Void: Grid не загружен.")
        return
    end

    local CONST = NSQC4.QuestsFieldConst
    local TOTAL = CONST and (CONST.COLS * CONST.ROWS) or 100

    -- ========================================================================
    -- IsVoid
    -- ========================================================================
    function Void:IsVoid(index)
        index = tonumber(index) or 0
        if index < 1 or index > TOTAL then return false end
        return Grid:GetTerrain(index) == "void"
    end

    -- ========================================================================
    -- EjectEntity: вытолкнуть существо из клетки index в случайную соседнюю
    -- не-void клетку без существа. Если соседей нет — существо остаётся.
    -- ========================================================================
    function Void:EjectEntity(index)
        index = tonumber(index) or 0
        if index < 1 or index > TOTAL then return false end

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

        -- перерисовать обе клетки
        local TerrainApi = NSQC4.QuestsDfTerrainUIApi
        if TerrainApi and TerrainApi.RenderCellFromStorage then
            TerrainApi:RenderCellFromStorage(index)
            TerrainApi:RenderCellFromStorage(target)
        end

        return true
    end

    -- ========================================================================
    -- Подсчёт void на текущем этаже
    -- ========================================================================
    function Void:CountVoid()
        local n = 0
        for i = 1, TOTAL do
            if Grid:GetTerrain(i) == "void" then
                n = n + 1
            end
        end
        return n
    end

    function Void:CountTotal()
        return TOTAL
    end

    function Void:PercentVoid()
        if TOTAL <= 0 then return 0 end
        return self:CountVoid() / TOTAL
    end

end)