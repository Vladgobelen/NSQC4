-- ============================================================================
-- NSQC4 / Quests / df / Floors / Storage
-- Хранение состояния этажей + отладка.
--
-- МОДЕЛЬ ДАННЫХ (исправлено):
--   byName — ГЛОБАЛЬНЫЙ реестр живых существ. Таблица entity живёт, пока
--   существо живо. Удаляется ТОЛЬКО в:
--     - Entities:Clear()    — полная генерация мира (RestartDfMap/Generate)
--     - Entities:Despawn()  — явное удаление существа
--   Переключение этажа НЕ удаляет таблицы существ.
--
--   Привязка существа к этажу — в snapshots[n].entities: кто из byName
--   находится на этаже n. Grid[idx].entityName — только для существ,
--   которые на ТЕКУЩЕМ этаже.
--
--   При SaveFloor(n):
--     - снимок берёт только тех, кто реально привязан к Grid (c.entityName)
--     - с Grid снимаются entityName тех существ, которые НЕ входят в снимок
--       этого этажа (они «на другом этаже»), чтобы Grid не помнил чужих.
--     - byName НЕ трогается — таблицы живут.
--
--   При LoadFloor(n):
--     - byName НЕ затирается. Для каждого rec из снимка — найти/создать
--       byName[rec.name], обновить index/opts/kind/step*.
--     - Существа, которых нет в снимке, остаются в byName (они на другом
--       этаже). Grid их не видит — там entityName снят при SaveFloor.
--     - stepT восстанавливается: stepStartedAt = now - stepT * stepDuration.
--
-- snapshots[n] = {
--     grid       = { [i] = { terrain, hardness, entityName, loot, depth } },
--     selections = { terrain_types = {...}, reserved = {...} },
--     entities   = { {
--         name, id, index, kind, opts = deep copy,
--         nextIndex, posX, posY,
--         stepStartX, stepStartY, stepEndX, stepEndY,
--         stepDuration, stepExpanded, stepT,
--     }, ... },
-- }
--
-- Отладка:
--   /ns_floors on | off | dump | snap <n> | byname
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

    -- ========================================================================
    -- Отладка
    -- ========================================================================
    Floors.DEBUG = true

    local function dbg(...)
        if Floors.DEBUG then print("|cff00ffff[FLOORS]|r", ...) end
    end

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
    -- byName доступ
    -- ========================================================================
    local function ByName()
        local E = NSQC4.QuestsDfEntities
        if not E then return {} end
        return E:EnsureByName()
    end

    -- ========================================================================
    -- Глубокие копии (opts содержит таблицы: known_skills, ai, gods, _minRoll)
    -- ========================================================================
    local function CopyTable(t)
        if type(t) ~= "table" then return t end
        local c = {}
        for k, v in pairs(t) do
            if type(v) == "table" then
                c[k] = CopyTable(v)
            else
                c[k] = v
            end
        end
        return c
    end

    local function CopyOpts(opts)
        if type(opts) ~= "table" then return opts end
        local c = {}
        for k, v in pairs(opts) do
            if k == "ai" or k == "known_skills" or k == "gods"
               or k == "_minRoll" or k == "_landscape" then
                c[k] = CopyTable(v)
            else
                c[k] = v
            end
        end
        return c
    end

    -- ========================================================================
    -- Снимок клеток (с depth)
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
                    loot       = c.loot and CopyTable(c.loot) or nil,
                    depth      = c.depth,
                }
            end
        end
        return snap
    end

    -- ========================================================================
    -- Снимок выделений
    -- ========================================================================
    local function SnapshotSelections()
        nsDbc4 = nsDbc4 or {}
        nsDbc4.quests = nsDbc4.quests or {}
        nsDbc4.quests.df = nsDbc4.quests.df or {}
        nsDbc4.quests.df.selections = nsDbc4.quests.df.selections or {}
        local s = nsDbc4.quests.df.selections

        local snap = { terrain_types = {}, reserved = {} }
        for tid, list in pairs(s.terrain_types or {}) do
            local copy = {}
            for idx in pairs(list) do copy[idx] = true end
            snap.terrain_types[tid] = copy
        end
        for idx, who in pairs(s.reserved or {}) do
            snap.reserved[idx] = who
        end
        return snap
    end

    -- ========================================================================
    -- Снимок существ этажа (byName + Grid)
    --   Сохраняет и состояние шага (nextIndex/posX/posY/step*/stepT),
    --   чтобы при загрузке продолжить движение, а не начинать заново.
    --
    --   В снимок попадают ТОЛЬКО существа, привязанные к Grid (c.entityName).
    --   Остальные остаются в byName и «живут» на других этажах.
    -- ========================================================================
    local function SnapshotEntities()
        local list = {}
        local byName = ByName()
        local now = GetTime()

        for name, e in pairs(byName) do
            if e and e.opts then
                local onGrid = false
                for i = 1, TOTAL do
                    local c = Grid:GetCell(i)
                    if c and c.entityName == name then
                        onGrid = true
                        break
                    end
                end
                if onGrid then
                    local t = nil
                    if e.nextIndex and e.stepStartedAt and e.stepDuration
                       and e.stepDuration > 0 then
                        t = (now - e.stepStartedAt) / e.stepDuration
                        if t < 0 then t = 0 elseif t > 1 then t = 1 end
                    end

                    list[#list + 1] = {
                        name  = name,
                        id    = e.id,
                        index = e.index,
                        kind  = e.kind,
                        opts  = CopyOpts(e.opts),

                        nextIndex    = e.nextIndex,
                        posX         = e.posX,
                        posY         = e.posY,
                        stepStartX   = e.stepStartX,
                        stepStartY   = e.stepStartY,
                        stepEndX     = e.stepEndX,
                        stepEndY     = e.stepEndY,
                        stepDuration = e.stepDuration,
                        stepExpanded = e.stepExpanded,
                        stepT        = t,
                    }
                end
            end
        end
        return list
    end

    -- ========================================================================
    -- Снять entityName с клеток Grid для существ, НЕ входящих в снимок этажа.
    --   Вызывается после SnapshotEntities: снимок уже собран, теперь Grid
    --   «забывает» чужих существ, чтобы они не всплыли при рендере.
    --   Таблицы этих существ остаются в byName — они на другом этаже.
    -- ========================================================================
    local function DetachNonSnapshotEntities(snapList)
        if not Grid then return end
        local inSnap = {}
        for _, rec in ipairs(snapList or {}) do
            inSnap[rec.name] = true
        end

        for i = 1, TOTAL do
            local c = Grid:GetCell(i)
            if c and c.entityName and not inSnap[c.entityName] then
                dbg(string.format("Detach: cell %d entityName %s (не в снимке этажа)",
                    i, tostring(c.entityName)))
                c.entityName = nil
            end
        end
    end

    -- ========================================================================
    -- Восстановить клетки из снимка (с depth)
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
                    c.loot       = sc.loot and CopyTable(sc.loot) or nil
                    c.depth      = sc.depth
                else
                    c.terrain    = nil
                    c.hardness   = nil
                    c.entityName = nil
                    c.loot       = nil
                    c.depth      = nil
                end
            end
        end
        return true
    end

    -- ========================================================================
    -- Восстановить выделения (или очистить)
    -- ========================================================================
    local function RestoreSelections(snap)
        nsDbc4 = nsDbc4 or {}
        nsDbc4.quests = nsDbc4.quests or {}
        nsDbc4.quests.df = nsDbc4.quests.df or {}
        nsDbc4.quests.df.selections = nsDbc4.quests.df.selections or {}
        local s = nsDbc4.quests.df.selections

        if not snap then
            s.terrain_types = {}
            s.reserved      = {}
            return
        end

        local newTypes = {}
        for tid, list in pairs(snap.terrain_types or {}) do
            local copy = {}
            for idx in pairs(list) do copy[idx] = true end
            newTypes[tid] = copy
        end
        s.terrain_types = newTypes

        local newRes = {}
        for idx, who in pairs(snap.reserved or {}) do
            newRes[idx] = who
        end
        s.reserved = newRes
    end

    -- ========================================================================
    -- Восстановить существ из снимка.
    --
    -- ГЛАВНОЕ ОТЛИЧИЕ ОТ СТАРОЙ ВЕРСИИ:
    --   byName НЕ затирается. Мы только обновляем/добавляем записи из снимка.
    --   Существа, которых нет в снимке, остаются в byName (они на другом
    --   этаже). Их таблицы живут до явного Despawn/Clear.
    --
    --   stepT восстанавливается: stepStartedAt = now - stepT * stepDuration,
    --   чтобы движение продолжилось с той же точки, а не началось заново.
    -- ========================================================================
    local function RestoreEntities(snapList)
        local E = NSQC4.QuestsDfEntities
        if not E then return end
        local byName = E:EnsureByName()

        if not snapList then return end

        local now = GetTime()
        local restored, created = 0, 0

        for _, rec in ipairs(snapList) do
            local name = rec.name
            local opts = rec.opts and CopyOpts(rec.opts) or {}
            local entity = byName[name]

            if not entity then
                entity = { id = rec.id }
                byName[name] = entity
                created = created + 1
            else
                restored = restored + 1
            end

            entity.id    = rec.id or entity.id
            entity.index = rec.index
            entity.opts  = opts
            entity.kind  = rec.kind or opts.kind or "generic"

            -- восстановить шаг, если существо было в пути
            if rec.nextIndex then
                entity.nextIndex     = rec.nextIndex
                entity.posX          = rec.posX
                entity.posY          = rec.posY
                entity.stepStartX    = rec.stepStartX
                entity.stepStartY    = rec.stepStartY
                entity.stepEndX      = rec.stepEndX
                entity.stepEndY      = rec.stepEndY
                entity.stepDuration  = rec.stepDuration
                entity.stepExpanded  = rec.stepExpanded
                local t = rec.stepT or 0
                if t < 0 then t = 0 elseif t > 1 then t = 1 end
                entity.stepStartedAt = now - t * (rec.stepDuration or 1)
            else
                entity.nextIndex     = nil
                entity.posX          = nil
                entity.posY          = nil
                entity.stepStartX    = nil
                entity.stepStartY    = nil
                entity.stepEndX      = nil
                entity.stepEndY      = nil
                entity.stepStartedAt = nil
                entity.stepDuration  = nil
                entity.stepExpanded  = nil
            end

            if rec.index and Grid then
                Grid:SetEntityName(rec.index, name)
            end
        end

        -- Диагностика: кто в byName, но не на этом этаже
        local totalByName = 0
        for _ in pairs(byName) do totalByName = totalByName + 1 end
        if totalByName > (restored + created) then
            dbg(string.format(
                "RestoreEntities: onFloor=%d (restored=%d, created=%d), всего в byName=%d (остальные на других этажах)",
                restored + created, restored, created, totalByName))
        end
    end

    -- ========================================================================
    -- Публичный доступ к снимку
    -- ========================================================================
    function Floors:GetSnapshot(n)
        n = tonumber(n) or 0
        return EnsureStorage().snapshots[n]
    end

    -- ========================================================================
    -- ApplyWaterFromAbove(n)
    -- ========================================================================
    function Floors:ApplyWaterFromAbove(n)
        n = tonumber(n) or 0
        local above = EnsureStorage().snapshots[n + 1]
        if not above or not above.grid then
            dbg(string.format("ApplyWaterFromAbove(%d): нет снимка этажа %d", n, n + 1))
            return 0
        end

        local Terrain = NSQC4.QuestsDfTerrain
        if not Terrain then return 0 end

        local placed = 0
        for i = 1, TOTAL do
            local up = above.grid[i]
            if up and up.terrain == "water" then
                local upDepth = tonumber(up.depth) or 0
                if upDepth >= 1 then
                    local newDepth = upDepth - 1
                    if newDepth >= 1 then
                        Terrain:SetAt(i, "water")
                        if Grid and Grid.SetDepth then
                            Grid:SetDepth(i, newDepth)
                        end
                        placed = placed + 1
                    else
                        Terrain:SetAt(i, "earth")
                        if Grid and Grid.ClearDepth then
                            Grid:ClearDepth(i)
                        end
                    end
                end
            end
        end

        dbg(string.format("ApplyWaterFromAbove(%d): поставлено воды %d", n, placed))
        return placed
    end

    -- ========================================================================
    -- SaveFloor(n)
    --   1. Собрать снимок существ ТОЛЬКО с текущего Grid (по entityName).
    --   2. Снять entityName с клеток Grid для тех, кто не в снимке
    --      (они уходят на другой этаж). Таблицы в byName остаются жить.
    --   3. Записать снимок.
    -- ========================================================================
    function Floors:SaveFloor(n)
        n = tonumber(n) or 0
        local s = EnsureStorage()

        local ents = SnapshotEntities()        -- 1. кто на этом этаже
        DetachNonSnapshotEntities(ents)        -- 2. Grid забывает чужих

        s.snapshots[n] = {
            grid       = SnapshotGrid(),
            selections = SnapshotSelections(),
            entities   = ents,
        }
        s.visited[n] = true
        if n < s.min then s.min = n end
        if n > s.max then s.max = n end

        local byNameCount = 0
        for _ in pairs(ByName()) do byNameCount = byNameCount + 1 end
        dbg(string.format(
            "SaveFloor(%d): entities=%d, byName всего=%d (живут глобально)",
            n, #ents, byNameCount))
        return true
    end

    -- ========================================================================
    -- LoadFloor(n)
    --   1. Скрыть все визуальные фреймы существ (ClearAllVisuals).
    --   2. Восстановить Grid + selections из снимка.
    --   3. Восстановить/обновить существ из снимка. byName НЕ затирается.
    --   4. Существа не из снимка остаются в byName — они на другом этаже.
    -- ========================================================================
    function Floors:LoadFloor(n)
        n = tonumber(n) or 0
        local s = EnsureStorage()
        local snap = s.snapshots[n]

        -- Скрыть все фреймы существ старого этажа ДО восстановления нового
        local EntApi = NSQC4.QuestsDfEntitiesUIApi
        if EntApi and EntApi.ClearAllVisuals then
            EntApi:ClearAllVisuals()
        end

        if not snap then
            dbg(string.format("LoadFloor(%d): нет снимка → очищаю Grid (byName не трогаю)", n))
            -- Очищаем Grid, но НЕ byName. Существа остаются жить —
            -- они просто не привязаны к клеткам этого этажа.
            if Grid and Grid.ClearAll then Grid:ClearAll() end
            return false
        end

        RestoreGrid(snap.grid)
        RestoreSelections(snap.selections)
        RestoreEntities(snap.entities)

        local byNameCount = 0
        for _ in pairs(ByName()) do byNameCount = byNameCount + 1 end
        dbg(string.format(
            "LoadFloor(%d): onFloor=%d, byName всего=%d",
            n, #(snap.entities or {}), byNameCount))
        return true
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

    -- ========================================================================
    -- Отладочные команды
    -- ========================================================================
    local function DumpFloors()
        local s = EnsureStorage()
        print(string.format("[FLOORS] current=%d min=%d max=%d", s.current, s.min, s.max))
        for n, snap in pairs(s.snapshots) do
            local ec = snap.entities and #snap.entities or 0
            local gcount = 0
            local wcount = 0
            if snap.grid then
                for i = 1, TOTAL do
                    if snap.grid[i] and snap.grid[i].terrain then
                        gcount = gcount + 1
                        if snap.grid[i].terrain == "water" then
                            wcount = wcount + 1
                        end
                    end
                end
            end
            print(string.format("  floor %d: cells=%d water=%d entities=%d",
                n, gcount, wcount, ec))
        end

        local byName = ByName()
        local total = 0
        for _ in pairs(byName) do total = total + 1 end
        print(string.format("  byName (глобально живых существ): %d", total))
    end

    local function DumpSnap(n)
        local s = EnsureStorage()
        local snap = s.snapshots[n]
        if not snap then
            print("[FLOORS] нет снимка этажа " .. tostring(n))
            return
        end
        print(string.format("[FLOORS] snap floor %d:", n))
        if snap.entities then
            for _, rec in ipairs(snap.entities) do
                local ai = rec.opts and rec.opts.ai
                print(string.format(
                    "  entity %s idx=%s kind=%s state=%s target=%s next=%s pos=(%s,%s) stepT=%s",
                    tostring(rec.name), tostring(rec.index), tostring(rec.kind),
                    tostring(ai and ai.state), tostring(ai and ai.target),
                    tostring(rec.nextIndex),
                    tostring(rec.posX), tostring(rec.posY),
                    tostring(rec.stepT)))
            end
        else
            print("  entities: nil")
        end
        if snap.grid then
            local parts = {}
            for i = 1, TOTAL do
                local c = snap.grid[i]
                if c and c.terrain == "water" then
                    parts[#parts + 1] = string.format("%d(d=%s)", i, tostring(c.depth))
                end
            end
            if #parts > 0 then
                print("  water: " .. table.concat(parts, " "))
            else
                print("  water: (нет)")
            end
        end
    end

    local function DumpByName()
        local byName = ByName()
        local total = 0
        for name, e in pairs(byName) do
            total = total + 1
            local ai = e.opts and e.opts.ai
            print(string.format("[FLOORS] byName %s id=%s idx=%s kind=%s state=%s target=%s next=%s pos=(%s,%s)",
                tostring(name), tostring(e.id), tostring(e.index),
                tostring(e.kind),
                tostring(ai and ai.state), tostring(ai and ai.target),
                tostring(e.nextIndex),
                tostring(e.posX), tostring(e.posY)))
        end
        print(string.format("[FLOORS] byName: всего %d (таблицы живут до Despawn/Clear)", total))
    end

    SLASH_NSFLOORS1 = "/ns_floors"
    SlashCmdList["NSFLOORS"] = function(msg)
        local cmd, arg = (msg or ""):match("^(%S*)%s*(.-)$")
        cmd = (cmd or ""):lower()
        if cmd == "" or cmd == "dump" then
            DumpFloors()
        elseif cmd == "snap" then
            DumpSnap(tonumber(arg) or 0)
        elseif cmd == "byname" then
            DumpByName()
        elseif cmd == "on" then
            Floors.DEBUG = true
            print("[FLOORS] DEBUG = true")
        elseif cmd == "off" then
            Floors.DEBUG = false
            print("[FLOORS] DEBUG = false")
        else
            print("[FLOORS] /ns_floors dump | snap <n> | byname | on | off")
        end
    end

    print("|cff00ffff[FLOORS]|r Floors/Storage загружен (byName глобальный, таблицы живут до Despawn/Clear; DEBUG=" .. tostring(Floors.DEBUG) .. ")")

end)