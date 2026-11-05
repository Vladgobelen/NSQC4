-- ============================================================================
-- NSQC4 / Quests / df / AI / Path
-- Поиск кратчайшего маршрута по сетке 10×10 (BFS, 4-связность).
--
-- ВАЖНО (модель движения):
--   Path:Find(startIndex, targetIndex, entity) считает от entity.index —
--   текущей клетки, где существо ЧИСЛИТСЯ. Пока существо идёт между
--   центрами клеток, entity.index не меняется (см. Move:Advance).
--   Значит, Path всегда строит маршрут от реальной текущей клетки.
--
-- Проходимость:
--   - старт: всегда проходим (существо там стоит)
--   - цель:  не void, не вода (если не canSwim)
--   - промежуточная: не void, не вода (если не canSwim), не занята другим
--
-- ОТЛАДКА:
--   /ns_path on | off | dump
--   Path.DEBUG = true/false
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Path = {}
    NSQC4.QuestsDfAIPath = Path
    Path.DEBUG = false

    local function dbg(...)
        if Path.DEBUG then print("|cff00ffff[PATH]|r", ...) end
    end

    local Grid = NSQC4.QuestsDfGrid
    if not Grid then
        print("|cffff0000[NSQC4]|r AI/Path: Grid не загружен.")
        return
    end

    local CONST = NSQC4.QuestsFieldConst
    if not CONST then return end
    local TOTAL = CONST.COLS * CONST.ROWS

    -- ========================================================================
    -- Восстановить путь по prev[].
    -- ========================================================================
    local function Reconstruct(prev, startIdx, targetIdx)
        local path = {}
        local cur = targetIdx
        while cur ~= nil do
            path[#path + 1] = cur
            if cur == startIdx then break end
            cur = prev[cur]
        end

        local n = #path
        for i = 1, math.floor(n / 2) do
            path[i], path[n - i + 1] = path[n - i + 1], path[i]
        end
        return path
    end

    local function CellInfo(index)
        local c = Grid:GetCell(index)
        if not c then return string.format("cell=%s (нет клетки)", tostring(index)) end
        return string.format("cell=%s terrain=%s entityName=%s passable(raw)=%s",
            tostring(index), tostring(c.terrain), tostring(c.entityName),
            Grid:IsPassable(index) and "yes" or "no")
    end

    local function CellInfoEnt(index, entity)
        local c = Grid:GetCell(index)
        if not c then return string.format("cell=%s (нет клетки)", tostring(index)) end
        return string.format("cell=%s terrain=%s entityName=%s passable(ent)=%s",
            tostring(index), tostring(c.terrain), tostring(c.entityName),
            Grid:IsPassable(index, entity) and "yes" or "no")
    end

    -- ========================================================================
    -- CanEnter — можно ли войти в клетку.
    --   startIndex — старт (всегда проходим)
    --   targetIndex — цель (не void, не вода без canSwim)
    --   иначе — промежуточная
    -- ========================================================================
    local function CanEnter(neighbor, targetIndex, startIndex, entity, canSwim)
        if neighbor == startIndex then
            return true, nil
        end

        if neighbor == targetIndex then
            local c = Grid:GetCell(neighbor)
            if not c then return false, "nocell" end
            if c.terrain == "void" then return false, "void" end
            if c.terrain == "water" and not canSwim then return false, "water" end
            return true, nil
        end

        local c = Grid:GetCell(neighbor)
        if not c then return false, "nocell" end
        if c.terrain == "void" then return false, "void" end
        if c.terrain == "water" and not canSwim then return false, "water" end

        if c.entityName then
            local myName = entity and entity.opts and entity.opts.name
            if not myName or c.entityName ~= myName then
                return false, "occupied:" .. tostring(c.entityName)
            end
            return true, nil
        end

        return true, nil
    end

    -- ========================================================================
    -- Find — BFS.
    -- ========================================================================
    function Path:Find(startIndex, targetIndex, entity)
        startIndex  = tonumber(startIndex)  or 0
        targetIndex = tonumber(targetIndex) or 0

        if startIndex < 1 or startIndex > TOTAL then
            dbg(string.format("Find: start=%s вне диапазона", tostring(startIndex)))
            return nil
        end
        if targetIndex < 1 or targetIndex > TOTAL then
            dbg(string.format("Find: target=%s вне диапазона", tostring(targetIndex)))
            return nil
        end

        local canSwim = false
        local Resolve = NSQC4.QuestsDfProfessionsResolve
        if entity and Resolve and Resolve.CanSwim then
            canSwim = Resolve:CanSwim(entity) and true or false
        end

        local eName = entity and entity.opts and entity.opts.name or "?"

        dbg("=========================================================")
        dbg(string.format("Find start=%s target=%s entity=%s canSwim=%s",
            tostring(startIndex), tostring(targetIndex), tostring(eName), tostring(canSwim)))
        dbg("  " .. CellInfo(startIndex))
        dbg("  " .. CellInfoEnt(targetIndex, entity))

        if startIndex == targetIndex then
            dbg("  start == target → путь {start}")
            return { startIndex }
        end

        local prev    = {}
        local visited = {}
        local queue   = { startIndex }
        local head    = 1

        visited[startIndex] = true
        prev[startIndex]    = nil

        local blockVoid, blockWater, blockOccupied, blockNoCell = {}, {}, {}, {}
        local visitedCount = 0

        local function noteBlock(reason, neighbor)
            if reason == "void" then blockVoid[#blockVoid + 1] = neighbor
            elseif reason == "water" then blockWater[#blockWater + 1] = neighbor
            elseif reason == "nocell" then blockNoCell[#blockNoCell + 1] = neighbor
            elseif reason and reason:sub(1, 8) == "occupied" then
                blockOccupied[#blockOccupied + 1] = neighbor
            end
        end

        while head <= #queue do
            local cur = queue[head]
            head = head + 1
            visitedCount = visitedCount + 1

            local neighbors = Grid:Neighbors(cur)
            if Path.DEBUG then
                local c = Grid:GetCell(cur)
                dbg(string.format("BFS head=%d cur=%d terrain=%s entityName=%s neighbors={%s}",
                    head - 1, cur, tostring(c and c.terrain), tostring(c and c.entityName),
                    table.concat(neighbors, ",")))
            end

            for _, neighbor in ipairs(neighbors) do
                if not visited[neighbor] then
                    local ok, reason = CanEnter(neighbor, targetIndex, startIndex, entity, canSwim)
                    if ok then
                        visited[neighbor] = true
                        prev[neighbor]    = cur
                        queue[#queue + 1] = neighbor

                        if Path.DEBUG then
                            local c = Grid:GetCell(neighbor)
                            dbg(string.format("    neighbor=%d terrain=%s entityName=%s → enqueue",
                                neighbor, tostring(c and c.terrain), tostring(c and c.entityName)))
                        end

                        if neighbor == targetIndex then
                            local path = Reconstruct(prev, startIndex, targetIndex)
                            dbg(string.format("BFS done: visited=%d", visitedCount))
                            dbg(string.format("path found: len=%d [%s]",
                                #path, table.concat(path, ",")))
                            dbg("=========================================================")
                            return path
                        end
                    else
                        noteBlock(reason, neighbor)
                        if Path.DEBUG then
                            local c = Grid:GetCell(neighbor)
                            dbg(string.format("    neighbor=%d terrain=%s entityName=%s → block (%s)",
                                neighbor, tostring(c and c.terrain),
                                tostring(c and c.entityName), tostring(reason)))
                        end
                    end
                end
            end
        end

        if Path.DEBUG then
            dbg(string.format("BFS done: visited=%d queue exhausted", visitedCount))
            dbg("path NOT found")
            dbg(string.format("block summary: void=%d water=%d occupied=%d nocell=%d",
                #blockVoid, #blockWater, #blockOccupied, #blockNoCell))
            local function fmtList(t)
                if #t == 0 then return "[]" end
                return "[" .. table.concat(t, ",") .. "]"
            end
            if #blockVoid > 0     then dbg("  void:     " .. fmtList(blockVoid))     end
            if #blockWater > 0    then dbg("  water:    " .. fmtList(blockWater))    end
            if #blockOccupied > 0 then dbg("  occupied: " .. fmtList(blockOccupied)) end
            if #blockNoCell > 0   then dbg("  nocell:   " .. fmtList(blockNoCell))   end
            dbg("=========================================================")
        end

        return nil
    end

    -- ========================================================================
    -- /ns_path
    -- ========================================================================
    SLASH_NSPATH1 = "/ns_path"
    SlashCmdList["NSPATH"] = function(msg)
        local cmd = (msg or ""):lower():match("^(%S*)")
        if cmd == "" or cmd == "on" then
            Path.DEBUG = true
            print("[PATH] DEBUG = true")
        elseif cmd == "off" then
            Path.DEBUG = false
            print("[PATH] DEBUG = false")
        elseif cmd == "dump" then
            local Entities = NSQC4.QuestsDfEntities
            if not Entities then return end
            for _, e in ipairs(Entities:GetAll()) do
                local ai = e.opts and e.opts.ai
                if ai and ai.target then
                    local path = Path:Find(e.index, ai.target, e)
                    if path then
                        print(string.format("  %s idx=%s target=%s → len=%d [%s]",
                            tostring(e.opts.name), tostring(e.index), tostring(ai.target),
                            #path, table.concat(path, ",")))
                    else
                        print(string.format("  %s idx=%s target=%s → NO PATH",
                            tostring(e.opts.name), tostring(e.index), tostring(ai.target)))
                    end
                end
            end
        else
            print("[PATH] /ns_path on | off | dump")
        end
    end

    print("|cff00ffff[PATH]|r Path загружен (DEBUG=" .. tostring(Path.DEBUG) .. ")")
end)