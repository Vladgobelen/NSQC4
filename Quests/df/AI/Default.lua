-- ============================================================================
-- NSQC4 / Quests / df / AI / Default
-- Поведение по умолчанию.
--
-- НОВАЯ МОДЕЛЬ ДВИЖЕНИЯ (см. Move.lua):
--   entity.index      — клетка, где существо ЧИСЛИТСЯ
--   entity.nextIndex  — клетка, к центру которой идёт
--   entity.posX/posY  — реальная позиция (пиксели)
--   Move:Advance возвращает:
--     "moving"  — существо между центрами, ещё не дошло до nextIndex
--     "moved"   — дошло до центра промежуточной клетки, идёт дальше
--     "arrived" — дошло до центра последней клетки пути
--     "wait"    — ждём nextStepAt
--     nil       — ошибка/блокировка
--
-- Цикл стройки (builder):
--   idle → Pick(лестница) → идём к ближайшему материалу →
--   взяли 1 ед. в ai.carrying → идём к лестнице →
--   положили в клетку (Grid:AddStored) → строим порциями по 100 HP →
--   материал кончился → need_material → снова к материалу → … → DONE.
--
-- ОТЛАДКА:
--   /ns_def on | off | dump [name]
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Default = {}
    NSQC4.QuestsDfAIDefault = Default
    Default.DEBUG = false

    local function dbg(...)
        if Default.DEBUG then print("|cff00ffff[DEF]|r", ...) end
    end

    local State    = NSQC4.QuestsDfAIState
    local Find     = NSQC4.QuestsDfAIFind
    local Path     = NSQC4.QuestsDfAIPath
    local Move     = NSQC4.QuestsDfAIMove
    local Work     = NSQC4.QuestsDfAIWork
    local Complete = NSQC4.QuestsDfAIComplete

    if not (State and Find and Path and Move and Work and Complete) then
        print("|cffff0000[NSQC4]|r AI/Default: не все зависимости загружены.")
        return
    end

    local function PlayStartSound(entity)
        local Sound = NSQC4.QuestsDfAISound
        if Sound then
            Sound:PlayKind(entity.kind or (entity.opts and entity.opts.kind))
        end
    end

    local function DiagnosePath(entity, targetIndex)
        local Grid = NSQC4.QuestsDfGrid
        if not Grid then return end
        local c = Grid:GetCell(targetIndex)
        if not c then return end
        dbg(string.format("  target %s: terrain=%s entityName=%s passable(raw)=%s passable(ent)=%s",
            tostring(targetIndex), tostring(c.terrain), tostring(c.entityName),
            Grid:IsPassable(targetIndex) and "yes" or "no",
            Grid:IsPassable(targetIndex, entity) and "yes" or "no"))
    end

    -- ========================================================================
    -- Ближайшая клетка с материалом (по BFS-длине).
    -- ========================================================================
    local function FindClosestMaterialCell(entity, material)
        local Grid  = NSQC4.QuestsDfGrid
        local Drops = NSQC4.QuestsDfTransformDrops
        if not Grid or not Drops then return nil end
        local CONST = NSQC4.QuestsFieldConst
        local TOTAL = CONST.COLS * CONST.ROWS

        local bestIdx, bestLen = nil, math.huge
        for i = 1, TOTAL do
            if not Grid:IsReserved(i, entity.id) then
                local items = Drops:GetAll(i)
                for _, d in ipairs(items) do
                    if d.id == material then
                        local path = Path:Find(entity.index, i, entity)
                        if path and #path < bestLen then
                            bestIdx, bestLen = i, #path
                        end
                        break
                    end
                end
            end
        end
        return bestIdx
    end

    -- ========================================================================
    -- Проверка «цель ещё в задачах» — по workTarget.
    -- ========================================================================
    local function IsTargetStillSelected(entity)
        local ai = entity and entity.opts and entity.opts.ai
        if not ai then return false end
        local checkIdx = ai.workTarget or ai.target
        if not checkIdx or not ai.terrainId then return false end
        local Grid = NSQC4.QuestsDfGrid
        if not Grid then return true end
        return Grid:IsTerrainSelected(checkIdx, ai.terrainId) and true or false
    end

    -- ========================================================================
    -- Обработка прибытия (когда Move вернул "arrived").
    -- ========================================================================
    local function OnArrived(entity, ai, name)
        local Grid  = NSQC4.QuestsDfGrid
        local Drops = NSQC4.QuestsDfTransformDrops
        local bIdx  = ai.workTarget or ai.target

        -- ====================================================================
        -- BUILDER
        -- ====================================================================
        if ai.profId == "builder" then
            -- пришли к материалу (target != workTarget)
            if ai.target ~= bIdx then
                local hereItems = Drops and Drops:GetAll(ai.target) or {}
                local took = nil
                for _, d in ipairs(hereItems) do
                    local b = Grid:GetBuilding(bIdx)
                    local material = b and b.material or "wood"
                    if d.id == material then
                        local c = Grid:GetCell(ai.target)
                        if c and c.loot and c.loot[d.anchor] then
                            c.loot[d.anchor] = nil
                            local any = false
                            for _ in pairs(c.loot) do any = true; break end
                            if not any then c.loot = nil end
                            Drops:Render(ai.target)
                            State:SetCarrying(entity, material, 1)
                            took = material
                            break
                        end
                    end
                end
                if took then
                    local path = Path:Find(entity.index, bIdx, entity)
                    if not path then State:SetIdle(entity); return end
                    local ok = State:SetMoving(entity, bIdx, "ladder", "builder", path,
                        { workTarget = bIdx })
                    if not ok then State:SetIdle(entity); return end
                    dbg(string.format("%s took material %s → build %s",
                        tostring(name), tostring(took), tostring(bIdx)))
                    return
                end
            end

            -- пришли к лестнице: если несём материал — кладём
            if ai.carrying then
                local carry = ai.carrying
                Grid:AddStored(bIdx, carry.count or 1)
                ai.carrying = nil
                dbg(string.format("%s deposited %s → cell %s stored=%d",
                    tostring(name), tostring(carry.material), tostring(bIdx),
                    Grid:GetStored(bIdx)))
                local T = NSQC4.QuestsDfTerrainUIApi
                if T and T.RenderCellFromStorage then T:RenderCellFromStorage(bIdx) end
            end

            State:SetWorking(entity)
            return
        end

        -- ====================================================================
        -- Обычная работа
        -- ====================================================================
        if not ai.carrying then
            local hereItems = Drops and Drops:GetAll(ai.target) or {}
            local took = nil
            for _, d in ipairs(hereItems) do
                local b = Grid:GetBuilding(bIdx)
                local material = b and b.material or "wood"
                if d.id == material then
                    local c = Grid:GetCell(ai.target)
                    if c and c.loot and c.loot[d.anchor] then
                        c.loot[d.anchor] = nil
                        local any = false
                        for _ in pairs(c.loot) do any = true; break end
                        if not any then c.loot = nil end
                        Drops:Render(ai.target)
                        State:SetCarrying(entity, material, 1)
                        took = material
                        break
                    end
                end
            end
            if took then
                local path = Path:Find(entity.index, bIdx, entity)
                if not path then State:SetIdle(entity); return end
                local ok = State:SetMoving(entity, bIdx, "ladder", "builder", path,
                    { workTarget = bIdx })
                if not ok then State:SetIdle(entity); return end
                return
            end
        end

        State:SetWorking(entity)
    end

    -- ========================================================================
    -- Tick
    -- ========================================================================
    function Default:Tick(entity)
        if not entity or not entity.opts then return false end
        if entity.opts.sleeping then return false end

        local ai   = entity.opts.ai
        local name = entity.opts.name or entity.id

        -- снято выделение?
        if ai and ai.target and (ai.state == "moving" or ai.state == "working") then
            if not IsTargetStillSelected(entity) then
                dbg(string.format("%s: %s (terrain=%s) снято выделение → idle",
                    tostring(name), tostring(ai.workTarget or ai.target),
                    tostring(ai.terrainId)))
                State:SetIdle(entity)
                return true
            end
        end

        -- ====================================================================
        -- IDLE → выбор цели
        -- ====================================================================
        if State:IsIdle(entity) then
            local pick = Find:Pick(entity)
            if not pick then return false end

            if pick.demolish then
                local path = Path:Find(entity.index, pick.index, entity)
                if not path then DiagnosePath(entity, pick.index); return false end
                local ok = State:SetMoving(entity, pick.index, "ladder", nil, path,
                    { workTarget = pick.index })
                if not ok then return false end
                PlayStartSound(entity)
                return true
            end

            if pick.profId == "builder" then
                local Grid = NSQC4.QuestsDfGrid
                local bIdx = pick.index
                local stored = Grid.GetStored and Grid:GetStored(bIdx) or 0
                local carry = ai and ai.carrying

                -- 1. уже несём → сразу к лестнице
                if carry then
                    local path = Path:Find(entity.index, bIdx, entity)
                    if not path then DiagnosePath(entity, bIdx); return false end
                    local ok = State:SetMoving(entity, bIdx, "ladder", "builder", path,
                        { workTarget = bIdx })
                    if not ok then return false end
                    PlayStartSound(entity)
                    return true
                end

                -- 2. в клетке лестницы уже есть материал → строим
                if stored > 0 then
                    local path = Path:Find(entity.index, bIdx, entity)
                    if not path then DiagnosePath(entity, bIdx); return false end
                    local ok = State:SetMoving(entity, bIdx, "ladder", "builder", path,
                        { workTarget = bIdx })
                    if not ok then return false end
                    PlayStartSound(entity)
                    return true
                end

                -- 3. материала нет → к ближайшему
                local b = Grid:GetBuilding(bIdx)
                local material = b and b.material or "wood"
                local matIdx = FindClosestMaterialCell(entity, material)
                if not matIdx then
                    dbg(string.format("%s build: нет материала %s → idle",
                        tostring(name), tostring(material)))
                    return false
                end

                local path = Path:Find(entity.index, matIdx, entity)
                if not path then DiagnosePath(entity, matIdx); return false end
                local ok = State:SetMoving(entity, matIdx, "ladder", "builder", path,
                    { workTarget = bIdx, material = material })
                if not ok then return false end
                dbg(string.format("%s idle→moving material cell=%s → build cell=%s",
                    tostring(name), tostring(matIdx), tostring(bIdx)))
                PlayStartSound(entity)
                return true
            end

            -- обычная работа
            local path = Path:Find(entity.index, pick.index, entity)
            if not path then DiagnosePath(entity, pick.index); return false end
            local ok = State:SetMoving(entity, pick.index, pick.terrainId, pick.profId, path, nil)
            if not ok then return false end
            PlayStartSound(entity)
            return true
        end

        -- ====================================================================
        -- MOVING — четыре возможных исхода
        -- ====================================================================
        if State:IsMoving(entity) then
            local r = Move:Advance(entity)

            if r == "arrived" then
                -- дошли до центра последней клетки
                OnArrived(entity, ai, name)
                return true

            elseif r == "moved" then
                -- дошли до центра промежуточной — продолжаем (следующий тик)
                return true

            elseif r == "moving" then
                -- между центрами, ещё в пути
                return true

            elseif r == "wait" then
                -- ждём nextStepAt
                return true

            else
                -- nil / ошибка / блокировка
                dbg(string.format("%s moving: Move=%s → idle", tostring(name), tostring(r)))
                State:SetIdle(entity)
                return false
            end
        end

        -- ====================================================================
        -- WORKING
        -- ====================================================================
        if State:IsWorking(entity) then
            local done, reason = Work:Tick(entity)
            if done == true then
                Complete:Finish(entity)
                return true
            elseif done == false then
                if reason == "need_material" then
                    local Grid = NSQC4.QuestsDfGrid
                    local bIdx = ai.workTarget or ai.target
                    local b = Grid:GetBuilding(bIdx)
                    local material = b and b.material or "wood"
                    local matIdx = FindClosestMaterialCell(entity, material)
                    if not matIdx then
                        dbg(string.format("%s need_material: нет %s → idle",
                            tostring(name), tostring(material)))
                        State:SetIdle(entity)
                        return false
                    end
                    local path = Path:Find(entity.index, matIdx, entity)
                    if not path then State:SetIdle(entity); return false end
                    local ok = State:SetMoving(entity, matIdx, "ladder", "builder", path,
                        { workTarget = bIdx, material = material })
                    if not ok then State:SetIdle(entity); return false end
                    dbg(string.format("%s working→moving material cell=%s → build cell=%s",
                        tostring(name), tostring(matIdx), tostring(bIdx)))
                    return true
                end
                return true
            else
                State:SetIdle(entity); return false
            end
        end

        State:SetIdle(entity); return false
    end

    -- ========================================================================
    -- /ns_def
    -- ========================================================================
    SLASH_NSDEF1 = "/ns_def"
    SlashCmdList["NSDEF"] = function(msg)
        local cmd, arg = (msg or ""):match("^(%S*)%s*(.-)$")
        cmd = (cmd or ""):lower()

        if cmd == "" or cmd == "on" then
            Default.DEBUG = true
            print("[DEF] DEBUG = true")
        elseif cmd == "off" then
            Default.DEBUG = false
            print("[DEF] DEBUG = false")
        elseif cmd == "dump" then
            local name = (arg ~= "" and arg) or nil
            local Entities = NSQC4.QuestsDfEntities
            if not Entities then return end
            local list = name and { Entities:GetByName(name) } or Entities:GetAll()
            for _, e in ipairs(list) do
                if e then
                    local ai = e.opts and e.opts.ai
                    print(string.format("[DEF] %s idx=%s next=%s pos=(%.1f,%.1f) state=%s target=%s wt=%s terrain=%s carrying=%s pathIdx=%s/#%s",
                        tostring(e.opts and e.opts.name or e.id),
                        tostring(e.index), tostring(e.nextIndex),
                        e.posX or -1, e.posY or -1,
                        tostring(ai and ai.state),
                        tostring(ai and ai.target),
                        tostring(ai and ai.workTarget),
                        tostring(ai and ai.terrainId),
                        tostring(ai and ai.carrying and ai.carrying.material),
                        tostring(ai and ai.pathIdx),
                        tostring(ai and ai.path and #ai.path)))
                end
            end
        else
            print("[DEF] /ns_def on | off | dump [name]")
        end
    end

    print("|cff00ffff[DEF]|r AI/Default загружен (debug=" .. tostring(Default.DEBUG) .. ")")
end)