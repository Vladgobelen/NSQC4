-- ============================================================================
-- NSQC4 / Quests / df / Transform / Init
-- Реестр преобразований + Apply (раздача лута, смена terrain, выталкивание).
--
-- Отладка:
--   /ns_loot on | off | dump | map
--
-- ФИКС: при nextTerrain == "void" снимаем выделение с клетки,
-- иначе Find:Pick может выбрать устаревшую клетку и существо уйдёт в void.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Transform = {}
    NSQC4.QuestsDfTransform = Transform

    Transform.DEBUG = true

    local function dbg(...)
        if Transform.DEBUG then print("|cff00ffff[LOOT]|r", ...) end
    end

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

    local function ClearSelectionFor(index)
        local Grid = NSQC4.QuestsDfGrid
        if not Grid or not Grid.IsTerrainSelected then return end
        local isSel, oldType = Grid:IsTerrainSelected(index)
        if isSel and oldType then
            Grid:SetTerrainSelected(index, oldType, false)
        end
    end

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
            if not a then
                dbg(string.format("  self: cell %d — нет свободного якоря, дроп %s пропал", index, tostring(def.drop)))
                break
            end
            placed = placed + 1
            dbg(string.format("  self: cell %d anchor %s ← %s", index, tostring(a), tostring(def.drop)))
        end
        return placed
    end

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
        if total <= 0 then
            dbg(string.format("  neighbors: cell %d — дропов 0 (min=%d,max=%d)", index, minN, maxN))
            return 0
        end

        local neighbors = Grid:Neighbors(index)
        local placed = 0

        for i = 1, total do
            local shuffled = {}
            for j = 1, #neighbors do shuffled[j] = neighbors[j] end
            for j = #shuffled, 2, -1 do
                local k = math.random(j)
                shuffled[j], shuffled[k] = shuffled[k], shuffled[j]
            end

            local chosen = nil
            local tries = {}
            for _, n in ipairs(shuffled) do
                local roll = math.random()
                local ok = (roll < 0.5)
                tries[#tries + 1] = string.format("%d:%s(%.2f)", n, ok and "Y" or "n", roll)
                if ok then
                    local free = Drops:FreeAnchors(n)
                    if #free > 0 then
                        chosen = n
                        break
                    end
                end
            end

            if chosen then
                local a = Drops:Add(chosen, def.drop, def.dropIcon)
                if a then
                    placed = placed + 1
                    dbg(string.format("  neighbors: drop %d/%d cell %d anchor %s ← %s  [%s]",
                        i, total, chosen, tostring(a), tostring(def.drop), table.concat(tries, " ")))
                else
                    dbg(string.format("  neighbors: drop %d/%d cell %d — Add вернул nil  [%s]",
                        i, total, chosen, table.concat(tries, " ")))
                end
            else
                dbg(string.format("  neighbors: drop %d/%d — никто не подошёл  [%s]",
                    i, total, table.concat(tries, " ")))
            end
        end
        return placed
    end

    local function EjectEntity(index)
        local Void = NSQC4.QuestsDfTransformVoid
        if Void and Void.EjectEntity then
            local ok = Void:EjectEntity(index)
            dbg(string.format("  eject: cell %d → %s", index, ok and "ok" or "некуда"))
            return ok
        end

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
        dbg(string.format("  eject: cell %d → cell %d", index, target))
        return true
    end

    function Transform:Apply(index, terrainId)
        index = tonumber(index) or 0
        if index < 1 then return false end

        local def = self:Get(terrainId)
        if not def then
            dbg(string.format("Apply: cell %d terrain=%s — нет def, пропуск", index, tostring(terrainId)))
            return false
        end

        local Terrain = NSQC4.QuestsDfTerrain
        if not Terrain then return false end

        dbg(string.format("Apply: cell %d terrain=%s next=%s drop=%s min=%s max=%s target=%s",
            index, tostring(terrainId), tostring(def.nextTerrain), tostring(def.drop),
            tostring(def.dropMin), tostring(def.dropMax), tostring(def.dropTarget)))

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

        if def.nextTerrain then
            if isVoidNext then
                ClearSelectionFor(index)
            end
            Terrain:SetTerrain(index, def.nextTerrain)
            dbg(string.format("  terrain: cell %d → %s", index, tostring(def.nextTerrain)))
        end

        if isVoidNext or def.eject then
            EjectEntity(index)
        end

        return true
    end

    -- ========================================================================
    -- Отладочные команды
    -- ========================================================================
    local function DumpLoot()
        local Drops = NSQC4.QuestsDfTransformDrops
        local Terrain = NSQC4.QuestsDfTerrain
        if not Drops or not Terrain then
            print("[LOOT] dump: Drops/Terrain не загружены")
            return
        end
        print("[LOOT] dump — клетки с лутом:")
        local found = 0
        for i = 1, 100 do
            if Drops:HasAny(i) then
                found = found + 1
                local t = Terrain:GetAt(i) or "?"
                local items = Drops:GetAll(i)
                local parts = {}
                for _, d in ipairs(items) do
                    parts[#parts + 1] = string.format("%s@%s", tostring(d.id), tostring(d.anchor))
                end
                print(string.format("  cell %d (%s): %s", i, tostring(t), table.concat(parts, ", ")))
            end
        end
        if found == 0 then print("  (пусто)") else print(string.format("  всего: %d", found)) end
    end

    local function DumpMap()
        local Drops = NSQC4.QuestsDfTransformDrops
        local Terrain = NSQC4.QuestsDfTerrain
        if not Drops or not Terrain then return end
        local CH = { earth="E", grass="G", stone="S", tree="T", pool="P", void=".", ladder="L" }
        print("[LOOT] map:")
        for row = 9, 0, -1 do
            local line = ""
            for col = 0, 9 do
                local idx = row * 10 + col + 1
                local t = Terrain:GetAt(idx)
                local ch = CH[t or ""] or "?"
                local n = Drops:Count(idx)
                if n > 0 then line = line .. string.format("%s%d ", ch, n)
                else line = line .. ch .. "  " end
            end
            print("  " .. line)
        end
    end

    SLASH_NSLOOT1 = "/ns_loot"
    SlashCmdList["NSLOOT"] = function(msg)
        local cmd = (msg or ""):lower():match("^(%S*)")
        if cmd == "" or cmd == "on" then
            Transform.DEBUG = true
            print("[LOOT] DEBUG = true")
        elseif cmd == "off" then
            Transform.DEBUG = false
            print("[LOOT] DEBUG = false")
        elseif cmd == "dump" then
            DumpLoot()
        elseif cmd == "map" then
            DumpMap()
        else
            print("[LOOT] /ns_loot on | off | dump | map")
        end
    end

    print("|cff00ffff[TRANSFORM]|r Transform/Init загружен (DEBUG=" .. tostring(Transform.DEBUG) .. ")")

end)