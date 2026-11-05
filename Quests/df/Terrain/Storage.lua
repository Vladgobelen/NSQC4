-- ============================================================================
-- NSQC4 / Quests / df / Terrain / Storage
-- Хранилище ландшафта: адаптер к общему Grid + точка входа рендера.
--
-- Terrain:Clear() теперь ещё и чистит Grid:ClearAllSelections("terrain"),
-- чтобы после generate/restart не оставались старые выделения
-- (grass[56], stone[57] и т.п.). Иначе существа «залипают» на них.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Terrain = NSQC4.QuestsDfTerrain
    if not Terrain then return end

    local CONST = NSQC4.QuestsFieldConst
    if not CONST then return end
    local TOTAL = CONST.COLS * CONST.ROWS

    local Grid = NSQC4.QuestsDfGrid
    if not Grid then return end

    local function UIApi()
        return NSQC4.QuestsDfTerrainUIApi
    end

    local function TerrainData()
        return NSQC4.QuestsDfTerrainData
    end

    local function RenderCell(index)
        local api = UIApi()
        if api and api.RenderCellFromStorage then
            api:RenderCellFromStorage(index)
        end
    end

    local function RenderAll()
        local api = UIApi()
        if api and api.RenderAll then
            api:RenderAll()
        end
    end

    local function ClearCellClicks(index)
        local QuestsField = NSQC4.QuestsField
        if not QuestsField then return end
        if QuestsField.ClearCellMouse then
            QuestsField:ClearCellMouse(index, "LeftButton")
            QuestsField:ClearCellMouse(index, "RightButton")
        end
    end

    local function EnsureTable()
        nsDbc4 = nsDbc4 or {}
        nsDbc4.quests = nsDbc4.quests or {}
        nsDbc4.quests.df = nsDbc4.quests.df or {}
        nsDbc4.quests.df.terrain = nsDbc4.quests.df.terrain or {}

        local s = nsDbc4.quests.df.terrain
        s.types = s.types or {}
        s.initialized = s.initialized and true or false
        return s
    end

    function Terrain:EnsureStorage() return EnsureTable() end
    function Terrain:IsInitialized() return EnsureTable().initialized and true or false end
    function Terrain:SetInitialized(v) EnsureTable().initialized = v and true or false end

    -- ========================================================================
    -- Реестр типов
    -- ========================================================================
    function Terrain:RegisterType(id, opts)
        if type(id) ~= "string" or id == "" then return nil end
        local s = EnsureTable()
        s.types[id] = opts or {}
        return s.types[id]
    end

    function Terrain:GetType(id)
        local s = EnsureTable()
        return s.types[id]
    end

    function Terrain:GetTypes()
        return EnsureTable().types
    end

    -- ========================================================================
    -- Карта
    -- ========================================================================
    function Terrain:GetAt(index)
        return Grid:GetTerrain(index)
    end

    function Terrain:SetAt(index, terrainId, opts)
        index = tonumber(index) or 0
        if index < 1 or index > TOTAL then return false end
        if type(terrainId) ~= "string" or terrainId == "" then return false end

        local s = EnsureTable()
        if opts and not s.types[terrainId] then
            s.types[terrainId] = opts
        end

        Grid:SetTerrain(index, terrainId)

        local Data = TerrainData()
        local def = Data and Data:Get(terrainId)
        if def and def.hardness then
            Grid:SetHardness(index, def.hardness)
        else
            Grid:ClearHardness(index)
        end

        RenderCell(index)
        return true
    end

    function Terrain:ClearAt(index)
        index = tonumber(index) or 0
        if index < 1 or index > TOTAL then return false end

        local current = Grid:GetTerrain(index)
        if not current then return false end

        if self:IsSelected(index) then
            self:ToggleSelect(index)
        end

        Grid:SetTerrain(index, nil)
        Grid:ClearHardness(index)
        ClearCellClicks(index)
        RenderCell(index)
        return true
    end

    function Terrain:Clear()
        for i = 1, TOTAL do
            if self:IsSelected(i) then
                self:ToggleSelect(i)
            end
            Grid:SetTerrain(i, nil)
            Grid:ClearHardness(i)
            ClearCellClicks(i)
        end
        RenderAll()

        -- Чистим старые выделения, чтобы после generate/restart
        -- существа не «залипали» на чужих terrain в клетке.
        if Grid.ClearAllSelections then
            Grid:ClearAllSelections("terrain")
        end
    end

    function Terrain:Count()
        local count = 0
        for i = 1, TOTAL do
            if Grid:GetTerrain(i) then count = count + 1 end
        end
        return count
    end

    -- ========================================================================
    -- Выделение
    -- ========================================================================
    function Terrain:ToggleSelect(index)
        index = tonumber(index) or 0
        if index < 1 or index > TOTAL then return false end

        local terrainId = Grid:GetTerrain(index)
        if not terrainId then return false end

        local isSelected = Grid:IsTerrainSelected(index)

        if isSelected then
            Grid:SetTerrainSelected(index, terrainId, false)
        else
            Grid:SetTerrainSelected(index, terrainId, true)
        end

        RenderCell(index)
        return true
    end

    function Terrain:IsSelected(index)
        return Grid:IsTerrainSelected(index)
    end

    function Terrain:ClearSelection()
        Grid:ClearAllSelections("terrain")
        RenderAll()
    end

    -- ========================================================================
    -- Рендер-вход
    -- ========================================================================
    function Terrain:RenderCell(index)
        RenderCell(index)
    end

    function Terrain:Render()
        RenderAll()
    end

end)