-- ============================================================================
-- NSQC4 / Quests / df / AI / Find
-- Выбор цели для существа.
--
-- ОТЛАДКА:
--   /ns_find on | off | dump
--   Find.DEBUG = true/false
--
--   При DEBUG=true каждый Pick печатает:
--     [FIND] =========================================================
--     [FIND] Pick entity=NAME kind=goblin canSwim=false
--     [FIND] ladder tasks: N
--     [FIND]   ladder 12 selected=yes hp=500/1000 mode=build by=nil
--     [FIND]   ladder 12 → task build (material=wood)
--     [FIND] selected cells: N
--     [FIND]   sel cell=19 terrain=earth fresh=yes allowed=yes reserved=no
--     [FIND]   sel cell=19 prof=digger → best
--     [FIND]   sel cell=21 terrain=tree fresh=yes allowed=yes reserved=no
--     [FIND]   sel cell=21 prof=nil (нет профессии) → rest
--     [FIND] pool: best=1 rest=0
--     [FIND] pick candidate cell=19 profId=digger → Path:Find...
--     [FIND]   path OK len=5 [74,84,94,95,19]
--     [FIND] → PICK cell=19 terrainId=earth profId=digger demolish=false
--     [FIND] → NO PICK (все недостижимы)
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Find = {}
    NSQC4.QuestsDfAIFind = Find
    Find.DEBUG = false

    local function dbg(...)
        if Find.DEBUG then print("|cff00ffff[FIND]|r", ...) end
    end

    local Grid = NSQC4.QuestsDfGrid
    if not Grid then
        print("|cffff0000[NSQC4]|r AI/Find: Grid не загружен.")
        return
    end

    local CONST = NSQC4.QuestsFieldConst
    if not CONST then return end
    local TOTAL = CONST.COLS * CONST.ROWS

    -- ========================================================================
    -- Allowed по виду
    -- ========================================================================
    local function GetAllowed(kind)
        if kind == "goblin" then
            local g = NSQC4.QuestsDfGoblin
            return g and g.Allowed or nil
        elseif kind == "dwarf" then
            local d = NSQC4.QuestsDfDwarf
            return d and d.Allowed or nil
        end
        return nil
    end

    -- ========================================================================
    -- Выделенные клетки из nsDbc4.quests.df.selections.terrain_types
    -- ========================================================================
    local function GetSelectedCells()
        local result = {}
        nsDbc4 = nsDbc4 or {}
        nsDbc4.quests = nsDbc4.quests or {}
        nsDbc4.quests.df = nsDbc4.quests.df or {}
        nsDbc4.quests.df.selections = nsDbc4.quests.df.selections or {}
        local s = nsDbc4.quests.df.selections
        local byType = s.terrain_types or {}
        for terrainId, list in pairs(byType) do
            for index in pairs(list) do
                result[#result + 1] = { index = index, terrainId = terrainId }
            end
        end
        return result
    end

    -- ========================================================================
    -- Профессия под terrain
    -- ========================================================================
    local function FindProfForTerrain(entity, terrainId)
        local ProfApi = NSQC4.QuestsDfProfessionsApi
        if not ProfApi then return nil end
        local opts = entity.opts
        if not opts or type(opts.known_skills) ~= "table" then return nil end
        for name, lvl in pairs(opts.known_skills) do
            local def = ProfApi:GetByName(name)
            if def and def.terrain == terrainId then
                return def
            end
        end
        return nil
    end

    local function HasBuilder(entity)
        return FindProfForTerrain(entity, "ladder") ~= nil
    end

    -- ========================================================================
    -- Свежесть выделенной клетки: terrain в Grid совпадает с terrainId в selection
    -- ========================================================================
    local function IsCellFresh(cell)
        if not cell then return false end
        local actual = Grid:GetTerrain(cell.index)
        if not actual then return false end
        if actual == "void" then return false end
        if actual ~= cell.terrainId then return false end
        return true
    end

    -- ========================================================================
    -- Проверка достижимости: Path:Find от текущей позиции до цели.
    -- Возвращает path | nil
    -- ========================================================================
    local function Reachable(entity, targetIndex)
        local Path = NSQC4.QuestsDfAIPath
        if not Path or not Path.Find then return nil end
        return Path:Find(entity.index, targetIndex, entity)
    end

    -- ========================================================================
    -- Задачи по лестнице. Только ВЫДЕЛЕННЫЕ.
    --   hp < max  → build (только если есть builder)
    --   hp >= max → demolish (любой)
    -- ========================================================================
    local function GetLadderTasks(entity)
        local result = {}
        local b = Grid.GetAllBuildings and Grid:GetAllBuildings() or {}
        dbg(string.format("ladder tasks scan: %d buildings", (function()
            local n = 0
            for _ in pairs(b) do n = n + 1 end
            return n
        end)()))

        for idx, rec in pairs(b) do
            if rec then
                local selected = Grid:IsTerrainSelected(idx, "ladder")
                local hp  = tonumber(rec.hp)  or 0
                local max = tonumber(rec.max) or 0

                if not selected then
                    dbg(string.format("  ladder %d selected=no hp=%s/%s → skip",
                        idx, hp, max))
                elseif rec.by and rec.by ~= entity.id then
                    dbg(string.format("  ladder %d selected=yes hp=%s/%s by=%s → skip (занята)",
                        idx, hp, max, tostring(rec.by)))
                elseif hp < max then
                    local hasB = HasBuilder(entity)
                    dbg(string.format("  ladder %d selected=yes hp=%s/%s mat=%s → task build (hasBuilder=%s)",
                        idx, hp, max, tostring(rec.material), tostring(hasB)))
                    if hasB then
                        result[#result + 1] = { index = idx, mode = "build", material = rec.material }
                    end
                elseif hp > 0 then
                    dbg(string.format("  ladder %d selected=yes hp=%s/%s → task demolish", idx, hp, max))
                    result[#result + 1] = { index = idx, mode = "demolish" }
                else
                    dbg(string.format("  ladder %d selected=yes hp=%s/%s → skip (hp<=0)", idx, hp, max))
                end
            end
        end
        return result
    end

    -- ========================================================================
    -- HasProfForSelected — используется Ticker'ом для приоритета.
    -- Проверяет: есть ли у существа хоть одна задача, которую он МОЖЕТ взять
    -- (без проверки достижимости — это дорого, а Ticker зовёт часто).
    -- ========================================================================
    function Find:HasProfForSelected(entity)
        if not entity or not entity.opts then return false end

        local tasks = GetLadderTasks(entity)
        for _, t in ipairs(tasks) do
            if t.mode == "demolish" then return true end
            if t.mode == "build" and HasBuilder(entity) then return true end
        end

        local kind = entity.kind or entity.opts.kind
        local allowed = GetAllowed(kind)
        if not allowed then return false end

        local selected = GetSelectedCells()
        for _, cell in ipairs(selected) do
            if IsCellFresh(cell) and allowed[cell.terrainId] then
                if FindProfForTerrain(entity, cell.terrainId) then
                    return true
                end
            end
        end
        return false
    end

    -- ========================================================================
    -- Pick — основной выбор.
    -- ========================================================================
    function Find:Pick(entity)
        if not entity or not entity.opts then return nil end

        local eName = entity.opts.name or entity.id
        local kind  = entity.kind or entity.opts.kind

        -- canSwim (для диагностики)
        local Resolve = NSQC4.QuestsDfProfessionsResolve
        local canSwim = false
        if Resolve and Resolve.CanSwim then
            canSwim = Resolve:CanSwim(entity) and true or false
        end

        dbg("=========================================================")
        dbg(string.format("Pick entity=%s kind=%s idx=%s canSwim=%s",
            tostring(eName), tostring(kind), tostring(entity.index), tostring(canSwim)))

        -- ====================================================================
        -- 1. Задачи по лестнице
        -- ====================================================================
        local tasks = GetLadderTasks(entity)
        dbg(string.format("ladder tasks: %d", #tasks))

        if #tasks > 0 then
            local demolish, build = {}, {}
            for _, t in ipairs(tasks) do
                if t.mode == "demolish" then
                    demolish[#demolish + 1] = t
                elseif t.mode == "build" and HasBuilder(entity) then
                    build[#build + 1] = t
                end
            end

            dbg(string.format("  pools: demolish=%d build=%d", #demolish, #build))

            local pool = (#demolish > 0) and demolish or (#build > 0 and build or nil)
            local mode = (#demolish > 0) and "demolish" or "build"

            if pool and #pool > 0 then
                -- Проверяем достижимость по очереди (начиная со случайного)
                local order = {}
                for i = 1, #pool do order[i] = i end
                for i = #order, 2, -1 do
                    local j = math.random(i)
                    order[i], order[j] = order[j], order[i]
                end

                for _, oi in ipairs(order) do
                    local pick = pool[oi]
                    dbg(string.format("  ladder cand cell=%d mode=%s → Path:Find...",
                        pick.index, mode))
                    local path = Reachable(entity, pick.index)
                    if path then
                        dbg(string.format("    path OK len=%d [%s]",
                            #path, table.concat(path, ",")))
                        local result
                        if mode == "demolish" then
                            result = { index = pick.index, terrainId = "ladder",
                                       profId = nil, demolish = true }
                        else
                            result = { index = pick.index, terrainId = "ladder",
                                       profId = "builder", demolish = false }
                        end
                        dbg(string.format("→ PICK ladder cell=%d mode=%s", pick.index, mode))
                        return result
                    else
                        dbg(string.format("    path FAIL (ladder cell=%d mode=%s)",
                            pick.index, mode))
                    end
                end
                dbg("  ladder: все кандидаты недостижимы")
            end
        end

        -- ====================================================================
        -- 2. Обычные выделенные клетки
        -- ====================================================================
        local allowed = GetAllowed(kind)
        if not allowed then
            dbg("allowed=nil → NO PICK")
            return nil
        end

        local selected = GetSelectedCells()
        dbg(string.format("selected cells: %d", #selected))

        local candidates = {}
        for _, cell in ipairs(selected) do
            local fresh = IsCellFresh(cell)
            local allow = allowed[cell.terrainId] and true or false
            local reserved = Grid:IsReserved(cell.index, entity.id) and true or false

            if cell.terrainId ~= "ladder" and fresh and allow and not reserved then
                candidates[#candidates + 1] = cell
                dbg(string.format("  sel cell=%d terrain=%s fresh=%s allowed=%s reserved=%s → candidate",
                    cell.index, tostring(cell.terrainId), tostring(fresh),
                    tostring(allow), tostring(reserved)))
            else
                local reason = "?"
                if cell.terrainId == "ladder" then reason = "ladder (обрабатывается выше)"
                elseif not fresh then reason = "stale"
                elseif not allow then reason = "not allowed"
                elseif reserved then reason = "reserved" end
                dbg(string.format("  sel cell=%d terrain=%s fresh=%s allowed=%s reserved=%s → skip (%s)",
                    cell.index, tostring(cell.terrainId), tostring(fresh),
                    tostring(allow), tostring(reserved), reason))
            end
        end

        if #candidates == 0 then
            dbg("no candidates → NO PICK")
            return nil
        end

        -- ====================================================================
        -- 3. best (с профессией) / rest (без)
        -- ====================================================================
        local best, rest = {}, {}
        for _, cell in ipairs(candidates) do
            local prof = FindProfForTerrain(entity, cell.terrainId)
            if prof then
                best[#best + 1] = { index = cell.index, terrainId = cell.terrainId, profId = prof.id }
                dbg(string.format("  sel cell=%d terrain=%s prof=%s → best",
                    cell.index, tostring(cell.terrainId), tostring(prof.id)))
            else
                rest[#rest + 1] = { index = cell.index, terrainId = cell.terrainId }
                dbg(string.format("  sel cell=%d terrain=%s prof=nil → rest",
                    cell.index, tostring(cell.terrainId)))
            end
        end

        local pool = (#best > 0) and best or rest
        dbg(string.format("pool: best=%d rest=%d → используем %s",
            #best, #rest, (#best > 0) and "best" or "rest"))

        if #pool == 0 then
            dbg("empty pool → NO PICK")
            return nil
        end

        -- ====================================================================
        -- 4. Проверка достижимости
        -- ====================================================================
        local order = {}
        for i = 1, #pool do order[i] = i end
        for i = #order, 2, -1 do
            local j = math.random(i)
            order[i], order[j] = order[j], order[i]
        end

        for _, oi in ipairs(order) do
            local pick = pool[oi]
            dbg(string.format("  pick candidate cell=%d terrain=%s profId=%s → Path:Find...",
                pick.index, tostring(pick.terrainId), tostring(pick.profId)))
            local path = Reachable(entity, pick.index)
            if path then
                dbg(string.format("    path OK len=%d [%s]",
                    #path, table.concat(path, ",")))
                dbg(string.format("→ PICK cell=%d terrainId=%s profId=%s demolish=false",
                    pick.index, tostring(pick.terrainId), tostring(pick.profId)))
                return pick
            else
                dbg(string.format("    path FAIL (cell=%d terrain=%s)",
                    pick.index, tostring(pick.terrainId)))
            end
        end

        dbg("→ NO PICK (все кандидаты недостижимы)")
        return nil
    end

    -- ========================================================================
    -- Слэш-команда
    -- ========================================================================
    SLASH_NSFIND1 = "/ns_find"
    SlashCmdList["NSFIND"] = function(msg)
        local cmd = (msg or ""):lower():match("^(%S*)")
        if cmd == "" or cmd == "on" then
            Find.DEBUG = true
            print("[FIND] DEBUG = true")
        elseif cmd == "off" then
            Find.DEBUG = false
            print("[FIND] DEBUG = false")
        elseif cmd == "dump" then
            local Entities = NSQC4.QuestsDfEntities
            if not Entities then
                print("[FIND] dump: Entities не загружен")
                return
            end
            print("[FIND] dump: прогон Pick для всех существ (без побочных эффектов)")
            local saved = Find.DEBUG
            Find.DEBUG = true
            for _, e in ipairs(Entities:GetAll()) do
                if e.opts and not e.opts.sleeping then
                    local ai = e.opts and e.opts.ai
                    if not ai or ai.state == "idle" then
                        print(string.format("[FIND] --- %s ---", tostring(e.opts.name)))
                        Find:Pick(e)
                    else
                        print(string.format("[FIND] %s: state=%s → пропуск dump",
                            tostring(e.opts.name), tostring(ai and ai.state)))
                    end
                end
            end
            Find.DEBUG = saved
        else
            print("[FIND] /ns_find on | off | dump")
        end
    end

    print("|cff00ffff[FIND]|r Find загружен (DEBUG=" .. tostring(Find.DEBUG) .. ")")

end)