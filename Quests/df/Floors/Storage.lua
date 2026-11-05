-- ============================================================================
-- NSQC4 / Quests / df / Floors / Storage
-- Хранение состояния этажей в nsDbc4.quests.df.floors.
--   current, min, max, visited
--   grid  — снимок клеток этажа (terrain, hardness, entityName, loot)
--
-- API:
--   Floors:Save()        — сохранить текущий этаж (снимок grid)
--   Floors:Load(n)       — загрузить этаж n (восстановить grid)
--   Floors:SaveFloor(n)  — сохранить этаж n
--   Floors:LoadFloor(n)  — загрузить этаж n
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Floors = NSQC4.QuestsDfFloors
    if not Floors then
        print("|cffff0000[NSQC4]|r Floors/Storage: Init.lua не загружен.")
        return
    end

    local Grid = NSQC4.QuestsDfGrid
    local CONST = NSQC4.QuestsFieldConst
    local TOTAL = CONST and (CONST.COLS * CONST.ROWS) or 100

    local function EnsureStorage()
        nsDbc4 = nsDbc4 or {}
        nsDbc4.quests = nsDbc4.quests or {}
        nsDbc4.quests.df = nsDbc4.quests.df or {}
        nsDbc4.quests.df.floors = nsDbc4.quests.df.floors or {}
        local s = nsDbc4.quests.df.floors
        s.current = s.current or 0
        s.min     = s.min or 0
        s.max     = s.max or 0
        s.visited = s.visited or { [0] = true }
        s.snapshots = s.snapshots or {}
        return s
    end

    function Floors:EnsureStorage() return EnsureStorage() end

    -- ========================================================================
    -- Снимок клеток текущего этажа (terrain, hardness, entityName, loot)
    -- ========================================================================
    local function SnapshotGrid()
        if not Grid then return nil end
        local snap = {}
        for i = 1, TOTAL do
            local c = Grid:GetCell(i)
            if c then
                snap[i] = {
                    terrain    = c.terrain,
                    hardness   = c.hardness,
                    entityName = c.entityName,
                    loot       = c.loot and (function()
                        local copy = {}
                        for a, d in pairs(c.loot) do
                            copy[a] = { id = d.id, icon = d.icon }
                        end
                        return copy
                    end)() or nil,
                }
            end
        end
        return snap
    end

    -- ========================================================================
    -- Восстановить клетки из снимка
    -- ========================================================================
    local function RestoreGrid(snap)
        if not Grid or not snap then return false end
        for i = 1, TOTAL do
            local c = Grid:GetCell(i)
            if c then
                local sc = snap[i]
                if sc then
                    c.terrain    = sc.terrain
                    c.hardness   = sc.hardness
                    c.entityName = sc.entityName
                    c.loot       = sc.loot
                else
                    c.terrain    = nil
                    c.hardness   = nil
                    c.entityName = nil
                    c.loot       = nil
                end
            end
        end
        return true
    end

    -- ========================================================================
    -- SaveFloor(n) / LoadFloor(n)
    -- ========================================================================
    function Floors:SaveFloor(n)
        n = tonumber(n) or 0
        local s = EnsureStorage()
        s.snapshots[n] = SnapshotGrid()
        s.visited[n] = true
        if n < s.min then s.min = n end
        if n > s.max then s.max = n end
        return true
    end

    function Floors:LoadFloor(n)
        n = tonumber(n) or 0
        local s = EnsureStorage()
        local snap = s.snapshots[n]
        if not snap then return false end
        return RestoreGrid(snap)
    end

    -- ========================================================================
    -- Save / Load (текущий этаж)
    -- ========================================================================
    function Floors:Save()
        local s = EnsureStorage()
        return self:SaveFloor(s.current)
    end

    function Floors:Load(n)
        n = n or self:Get()
        return self:LoadFloor(n)
    end

end)