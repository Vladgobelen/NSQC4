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
-- SetTerrainSelected снимает все другие типы в клетке.
-- Reserve / Release / IsReserved — резерв клетки под существо.
--
-- ПРОХОДИМОСТЬ (IsPassable):
--   Grid:IsPassable(index)          — «сырая»: void → false, занято → false.
--                                     Вода считается проходимой (terrain ~= void,
--                                     нет entityName). Для тех, кто не знает
--                                     про entity.
--   Grid:IsPassable(index, entity)  — с учётом entity: вода проходима ТОЛЬКО
--                                     если Resolve:CanSwim(entity) == true.
--                                     Иначе вода → false.
--                                     Это вторая линия защиты: Path/Move
--                                     уже фильтруют по Resolve:CanSwim, но
--                                     если кто-то забудет — Grid не пропустит.
--
--   Обратная совместимость: старые вызовы IsPassable(index) без entity
--   работают как раньше.
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
        end
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

    function Grid:ClearSelection(layer, id)
        if layer == "terrain" then
            local s = EnsureSelections()
            for terrainId, list in pairs(s.terrain_types) do
                if list[id] then list[id] = nil end
            end
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
    --
    --   Grid:IsPassable(index) — «сырая» проверка, БЕЗ entity:
    --     - void → false
    --     - есть entityName → false
    --     - вода → true (для тех, кто не знает про entity)
    --
    --   Grid:IsPassable(index, entity) — с учётом entity:
    --     - void → false
    --     - есть entityName → false
    --     - вода → только если Resolve:CanSwim(entity) == true
    --     - остальное → true
    --
    --   «Никто без пловца не пройдёт по воде» обеспечивается второй формой:
    --   Path/Move зовут Grid:IsPassable(neighbor, entity) — вода
    --   заблокирована для не-пловцов. Если кто-то забудет про Resolve в
    --   Path/Move, Grid всё равно не пропустит — двойная защита.
    -- ========================================================================
    function Grid:IsPassable(index, entity)
        local c = self:GetCell(index)
        if not c then return false end

        -- void — никогда
        if c.terrain == "void" then return false end

        -- занято существом — никогда (для «сырой» проверки)
        if c.entityName then return false end

        -- вода: без entity — «сырая» проходимость true;
        --        с entity — только для пловца
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

    print("|cff00ffff[GRID-DEBUG]|r Единый реестр клеток инициализирован (byName, loot, depth, void, water).")

end)