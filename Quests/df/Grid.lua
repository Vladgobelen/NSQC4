-- ============================================================================
-- NSQC4 / Quests / df / Grid
-- Единое хранилище клеток 10×10.
--
-- Модель byName:
--   nsDbc4.quests.df.entities.byName[name] = entity
--   grid[i].entityName = name
--
-- Grid:GetEntity(index) резолвит по byName → entity.
--
-- cell = { terrain, entityName, hardness, loot, depth }
--   loot  = { [anchor] = { id, icon }, ... }   -- лут в лут-якорях
--   depth = 1..10 | nil                        -- глубина воды (Grid/Depth.lua)
--
-- ВЫДЕЛЕНИЕ (шаг 10 — через API поля):
--   SetTerrainSelected снимает все другие типы в клетке И перерисовывает
--   клетку через QuestsField:RefreshCell(index) — поле само перечитает
--   данные Grid, соберёт полный spec (highlight) и перевесит тултип/клики.
--   df больше не зовёт TerrainUIApi:RenderCellFromStorage напрямую.
--
-- ВЫДЕЛЕНИЕ С ОТТЕНКОМ (шаг 2):
--   При выделении df-объект задаёт оттенок через
--   QuestsField:SetCellSelectTint(index, r,g,b,a).
--   При де-выделении SetTerrainSelected(..., false) снимает тинт сам —
--   чтобы df не звал ClearCellSelectTint в каждом LeftClickSelf.
--   RefreshCell читает btn._crSelectTint в приоритете над ResolveHighlight
--   (см. df/Terrain/UI/Api.lua → BuildSpec).
--
-- Reserve / Release / IsReserved — резерв клетки под существо.
--
-- ПРОХОДИМОСТЬ (IsPassable):
--   Grid:IsPassable(index)          — «сырая»: void → false, занято → false.
--                                     Вода считается проходимой.
--   Grid:IsPassable(index, entity)  — с учётом entity: вода проходима ТОЛЬКО
--                                     если Resolve:CanSwim(entity) == true.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Grid = {}
    NSQC4.QuestsDfGrid = Grid

    Grid.DEBUG = false

    local function dbg(...)
        if Grid.DEBUG then print("|cff00ffff[GRID]|r", ...) end
    end

    local CONST = NSQC4.QuestsFieldConst
    if not CONST then return end
    local TOTAL = CONST.COLS * CONST.ROWS

    local QuestsField = NSQC4.QuestsField

    -- Перерисовать клетку через API поля.
    --   Если поле/RefreshCell ещё не загружены (ранняя инициализация) —
    --   тихо возвращаем false, никто не падает.
    local function RefreshCell(index)
        if QuestsField and QuestsField.RefreshCell then
            return QuestsField:RefreshCell(index)
        end
        return false
    end

    -- ========================================================================
    -- Хранилище клеток
    -- ========================================================================
    local function EnsureGrid()
        nsDbc4 = nsDbc4 or {}
        nsDbc4.quests = nsDbc4.quests or {}
        nsDbc4.quests.df = nsDbc4.quests.df or {}
        nsDbc4.quests.df.grid = nsDbc4.quests.df.grid or {}
        local g = nsDbc4.quests.df.grid
        for i = 1, TOTAL do
            if not g[i] then
                g[i] = { terrain = nil, entityName = nil, hardness = nil, loot = nil, depth = nil }
            end
        end
        return g
    end

    local function EnsureByName()
        nsDbc4 = nsDbc4 or {}
        nsDbc4.quests = nsDbc4.quests or {}
        nsDbc4.quests.df = nsDbc4.quests.df or {}
        nsDbc4.quests.df.entities = nsDbc4.quests.df.entities or {}
        nsDbc4.quests.df.entities.byName = nsDbc4.quests.df.entities.byName or {}
        return nsDbc4.quests.df.entities.byName
    end

    local function EnsureSelections()
        nsDbc4 = nsDbc4 or {}
        nsDbc4.quests = nsDbc4.quests or {}
        nsDbc4.quests.df = nsDbc4.quests.df or {}
        nsDbc4.quests.df.selections = nsDbc4.quests.df.selections or {}
        local s = nsDbc4.quests.df.selections
        s.terrain_types = s.terrain_types or {}
        s.entity   = s.entity   or {}
        s.reserved = s.reserved or {}
        return s
    end

    -- ========================================================================
    -- Базовое API
    -- ========================================================================
    function Grid:GetCell(index)
        index = tonumber(index) or 0
        if index < 1 or index > TOTAL then return nil end
        return EnsureGrid()[index]
    end

    function Grid:ClearCell(index)
        index = tonumber(index) or 0
        if index < 1 or index > TOTAL then return end
        EnsureGrid()[index] = { terrain = nil, entityName = nil, hardness = nil, loot = nil, depth = nil }
    end

    function Grid:ClearAll()
        local g = EnsureGrid()
        for i = 1, TOTAL do
            g[i] = { terrain = nil, entityName = nil, hardness = nil, loot = nil, depth = nil }
        end
        local s = EnsureSelections()
        s.terrain_types = {}
        s.entity = {}
        s.reserved = {}
        EnsureByName()
    end

    -- ========================================================================
    -- Террейн
    -- ========================================================================
    function Grid:SetTerrain(index, terrainId)
        local c = self:GetCell(index)
        if c then c.terrain = terrainId end
    end

    function Grid:GetTerrain(index)
        local c = self:GetCell(index)
        return c and c.terrain
    end

    -- ========================================================================
    -- Существо в клетке
    -- ========================================================================
    function Grid:SetEntityName(index, name)
        local c = self:GetCell(index)
        if not c then return end
        if c.terrain == "void" and name then
            dbg("SetEntityName: нельзя ставить существо в void", index)
            return
        end
        c.entityName = name
    end

    function Grid:GetEntityName(index)
        local c = self:GetCell(index)
        return c and c.entityName
    end

    function Grid:GetEntity(index)
        local c = self:GetCell(index)
        if not c or not c.entityName then return nil end
        return EnsureByName()[c.entityName]
    end

    function Grid:SetEntity(index, entity)
        local c = self:GetCell(index)
        if not c then return end
        if c.terrain == "void" and entity then
            dbg("SetEntity: нельзя ставить существо в void", index)
            return
        end
        if entity and entity.opts and entity.opts.name then
            c.entityName = entity.opts.name
        else
            c.entityName = nil
        end
    end

    -- ========================================================================
    -- Выделение
    --
    -- Шаг 10: после изменения выделения — перерисовать клетку через
    -- QuestsField:RefreshCell(index). Это перечитывает Grid и собирает
    -- полный spec (highlight + тултип + клики), а не накладывает заплатку.
    --
    -- Шаг 2: при де-выделении снимаем btn._crSelectTint — чтобы df не
    -- звал ClearCellSelectTint в каждом LeftClickSelf.
    -- ========================================================================
    function Grid:SetTerrainSelected(index, terrainId, isSelected)
        local s = EnsureSelections()

        if isSelected then
            for tid, list in pairs(s.terrain_types) do
                if tid ~= terrainId and list[index] then
                    list[index] = nil
                end
            end
            if not s.terrain_types[terrainId] then s.terrain_types[terrainId] = {} end
            s.terrain_types[terrainId][index] = true
        else
            if s.terrain_types[terrainId] then
                s.terrain_types[terrainId][index] = nil
            end
            -- Снять оттенок выделения: df задаёт его через SetCellSelectTint
            -- при выделении; при де-выделении поле чистит само.
            local btn = QuestsField and QuestsField.cells and QuestsField.cells[index]
            if btn then btn._crSelectTint = nil end
        end

        -- Перерисовать клетку через API поля.
        RefreshCell(index)

        dbg("SetTerrainSelected", index, terrainId, isSelected and "ON" or "OFF")
    end

    function Grid:IsTerrainSelected(index, terrainId)
        local s = EnsureSelections()
        if terrainId then
            local list = s.terrain_types[terrainId]
            return (list and list[index]) and true or false
        end
        for tid, list in pairs(s.terrain_types) do
            if list[index] then return true, tid end
        end
        return false
    end

    function Grid:SetSelected(layer, id, isSelected)
        local s = EnsureSelections()
        if not s[layer] then s[layer] = {} end
        if isSelected then s[layer][id] = true else s[layer][id] = nil end
    end

    function Grid:IsSelected(layer, id)
        local s = EnsureSelections()
        return s[layer] and s[layer][id] == true
    end

    -- ========================================================================
    -- ClearSelection: для layer="terrain" снимаем ВСЕ выделения этого
    -- id-клетки и перерисовываем клетку (иначе highlight остаётся).
    -- Раньше перерисовки не было — теперь через API поля.
    -- ========================================================================
    function Grid:ClearSelection(layer, id)
        if layer == "terrain" then
            local s = EnsureSelections()
            local touched = false
            for terrainId, list in pairs(s.terrain_types) do
                if list[id] then
                    list[id] = nil
                    touched = true
                end
            end
            if touched then RefreshCell(id) end
        else
            self:SetSelected(layer, id, false)
        end
    end

    function Grid:ClearAllSelections(layer)
        local s = EnsureSelections()
        if layer == "terrain" then
            s.terrain_types = {}
        elseif layer == "reserved" then
            s.reserved = {}
        elseif layer then
            s[layer] = {}
        else
            s.terrain_types = {}
            s.entity = {}
            s.reserved = {}
        end
    end

    -- ========================================================================
    -- Резерв
    -- ========================================================================
    function Grid:Reserve(index, who)
        index = tonumber(index) or 0
        if index < 1 or index > TOTAL then return false end
        local s = EnsureSelections()
        s.reserved = s.reserved or {}
        s.reserved[index] = who
        dbg("Reserve", index, tostring(who))
        return true
    end

    function Grid:Release(index, who)
        index = tonumber(index) or 0
        if index < 1 or index > TOTAL then return false end
        local s = EnsureSelections()
        s.reserved = s.reserved or {}
        if not who or s.reserved[index] == who then
            s.reserved[index] = nil
        end
        dbg("Release", index, tostring(who))
        return true
    end

    function Grid:IsReserved(index, who)
        index = tonumber(index) or 0
        if index < 1 or index > TOTAL then return false end
        local s = EnsureSelections()
        s.reserved = s.reserved or {}
        local r = s.reserved[index]
        if not r then return false end
        if who and r == who then return false end
        return true
    end

    function Grid:GetReservedBy(index)
        local s = EnsureSelections()
        s.reserved = s.reserved or {}
        return s.reserved[tonumber(index) or 0]
    end

    -- ========================================================================
    -- Проходимость
    -- ========================================================================
    function Grid:IsPassable(index, entity)
        local c = self:GetCell(index)
        if not c then return false end

        if c.terrain == "void" then return false end
        if c.entityName then return false end

        if c.terrain == "water" and entity then
            local Resolve = NSQC4.QuestsDfProfessionsResolve
            local canSwim = false
            if Resolve and Resolve.CanSwim then
                canSwim = Resolve:CanSwim(entity) and true or false
            end
            if not canSwim then return false end
        end

        return true
    end

    -- ========================================================================
    -- Отладка
    -- ========================================================================
    function Grid:DumpSelections()
        local s = EnsureSelections()
        local total = 0
        for tid, list in pairs(s.terrain_types) do
            local cnt = 0
            local cells = {}
            for idx in pairs(list) do
                cnt = cnt + 1
                cells[#cells + 1] = tostring(idx)
            end
            total = total + cnt
            print(string.format("[GRID] terrain=%s cells=%d  [%s]", tid, cnt, table.concat(cells, ",")))
        end
        print("[GRID] total selected terrain cells:", total)

        local rcnt = 0
        local rcells = {}
        for idx, who in pairs(s.reserved) do
            rcnt = rcnt + 1
            rcells[#rcells + 1] = tostring(idx) .. "=" .. tostring(who)
        end
        print(string.format("[GRID] reserved=%d  [%s]", rcnt, table.concat(rcells, " ")))
    end

    print("|cff00ffff[GRID-DEBUG]|r Единый реестр клеток инициализирован (шаг 10: SetTerrainSelected/ClearSelection → QuestsField:RefreshCell; де-выделение снимает _crSelectTint).")

end)