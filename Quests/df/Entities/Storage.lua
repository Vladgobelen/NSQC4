-- ============================================================================
-- NSQC4 / Quests / df / Entities / Storage
-- Хранилище живых существ через byName:
--   nsDbc4.quests.df.entities.byName[name] = entity
--   grid[i].entityName = name
--
-- Entities:Spawn(id, index, opts) — opts.name должен быть свободен в byName.
-- Если занят — Spawn возвращает nil (Spawner должен был сгенерировать
-- уникальное имя сам).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Entities = NSQC4.QuestsDfEntities
    if not Entities then return end

    local CONST = NSQC4.QuestsFieldConst
    if not CONST then return end
    local TOTAL = CONST.COLS * CONST.ROWS

    local Grid = NSQC4.QuestsDfGrid
    if not Grid then return end

    local function ByName()
        return Entities:EnsureByName()
    end

    local function RenderCell(index)
        local TerrainApi = NSQC4.QuestsDfTerrainUIApi
        if TerrainApi and TerrainApi.RenderCellFromStorage then
            TerrainApi:RenderCellFromStorage(index)
        end
    end

    local function RenderAll()
        local TerrainApi = NSQC4.QuestsDfTerrainUIApi
        if TerrainApi and TerrainApi.RenderAll then
            TerrainApi:RenderAll()
        end
    end

    local function StopAnimation(id)
        local Animate = NSQC4.QuestsDfEntitiesAnimate
        if Animate and id and Animate.Stop then
            Animate:Stop(id)
        end
    end

    -- ========================================================================
    -- Флаг инициализации / авто-id
    -- ========================================================================
    local function EnsureTable()
        nsDbc4 = nsDbc4 or {}
        nsDbc4.quests = nsDbc4.quests or {}
        nsDbc4.quests.df = nsDbc4.quests.df or {}
        nsDbc4.quests.df.entities = nsDbc4.quests.df.entities or {}

        local s = nsDbc4.quests.df.entities
        s.nextId = s.nextId or 1
        s.initialized = s.initialized and true or false
        s.byName = s.byName or {}
        return s
    end

    function Entities:EnsureStorage() return EnsureTable() end
    function Entities:IsInitialized() return EnsureTable().initialized and true or false end
    function Entities:SetInitialized(v) EnsureTable().initialized = v and true or false end

    function Entities:EnsureUniqueId()
        local s = EnsureTable()
        local id = "e" .. s.nextId
        s.nextId = s.nextId + 1
        return id
    end

    -- ========================================================================
    -- Доступ
    -- ========================================================================
    function Entities:GetAt(index)
        return Grid:GetEntity(index)
    end

    function Entities:Get(id)
        if not id then return nil end
        for _, e in pairs(ByName()) do
            if e.id == id then return e end
        end
        return nil
    end

    function Entities:GetByName(name)
        if type(name) ~= "string" or name == "" then return nil end
        return ByName()[name]
    end

    function Entities:GetAll()
        local list = {}
        for _, e in pairs(ByName()) do
            list[#list + 1] = e
        end
        return list
    end

    function Entities:Count()
        local n = 0
        for _ in pairs(ByName()) do n = n + 1 end
        return n
    end

    -- ========================================================================
    -- Создание / перемещение
    -- ========================================================================
    function Entities:Spawn(id, index, opts)
        index = tonumber(index) or 0
        if index < 1 or index > TOTAL then return nil end
        if type(opts) ~= "table" then return nil end
        if type(opts.name) ~= "string" or opts.name == "" then return nil end

        local name = opts.name
        local byName = ByName()

        -- Коллизия по имени — Spawner должен был сгенерировать уникальное
        local existing = byName[name]
        if existing then
            -- Разрешаем только если это тот же id (перемещение / обновление)
            if id and existing.id ~= id then
                print("|cffff0000[NSQC4]|r Entities:Spawn: имя '" .. name .. "' уже занято (" .. tostring(existing.id) .. ")")
                return nil
            end
        end

        id = id or existing and existing.id or self:EnsureUniqueId()
        if type(id) ~= "string" then id = tostring(id) end

        if existing then
            StopAnimation(id)
            local oldIndex = existing.index
            if oldIndex and oldIndex ~= index then
                Grid:SetEntityName(oldIndex, nil)
                RenderCell(oldIndex)
            end
            existing.index = index
            existing.opts  = opts
            existing.kind  = opts.kind or existing.kind
            byName[name]   = existing
            Grid:SetEntityName(index, name)
            RenderCell(index)
            return existing
        end

        local entity = {
            id    = id,
            index = index,
            opts  = opts,
            kind  = opts.kind or "generic",
        }

        byName[name] = entity
        Grid:SetEntityName(index, name)
        RenderCell(index)
        return entity
    end

    -- ========================================================================
    -- Удаление
    -- ========================================================================
    function Entities:Despawn(id)
        StopAnimation(id)

        local byName = ByName()
        for name, e in pairs(byName) do
            if e.id == id then
                local idx = e.index
                byName[name] = nil
                if idx then
                    Grid:SetEntityName(idx, nil)
                    if Grid.ClearSelection then
                        Grid:ClearSelection("entity", id)
                    end
                    RenderCell(idx)
                end
                return true
            end
        end
        return false
    end

    function Entities:Move(id, newIndex)
        local entity = self:Get(id)
        if not entity then return false end
        return self:Spawn(entity.id, newIndex, entity.opts) ~= nil
    end

    function Entities:Clear()
        local Animate = NSQC4.QuestsDfEntitiesAnimate
        local byName = ByName()

        -- Скрыть все фреймы существ (Api._entityFrames) — они не привязаны к byName
        local EntApi = NSQC4.QuestsDfEntitiesUIApi
        if EntApi and EntApi.ClearAllVisuals then
            EntApi:ClearAllVisuals()
        end

        for name, e in pairs(byName) do
            if Animate and e.id then Animate:Stop(e.id) end
            if Grid.ClearSelection then
                Grid:ClearSelection("entity", e.id)
            end
            if e.index then
                Grid:SetEntityName(e.index, nil)
            end
            byName[name] = nil
        end

        for i = 1, TOTAL do
            RenderCell(i)
        end
    end

    -- ========================================================================
    -- Выделение (по id — как было)
    -- ========================================================================
    function Entities:ToggleSelect(id)
        local entity = self:Get(id)
        if not entity then return false end

        local isSel = Grid:IsSelected("entity", id)

        if isSel then
            Grid:ClearSelection("entity", id)
        else
            Grid:SetSelected("entity", id, true)
        end

        if entity.index then RenderCell(entity.index) end
        return true
    end

    function Entities:IsSelected(id)
        return Grid:IsSelected("entity", id)
    end

    function Entities:ClearSelection()
        Grid:ClearAllSelections("entity")
        RenderAll()
    end

    -- ========================================================================
    -- Рендер
    -- ========================================================================
    function Entities:RenderCell(index)
        RenderCell(index)
    end

    function Entities:Render()
        RenderAll()
    end

end)