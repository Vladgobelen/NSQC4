-- ============================================================================
-- NSQC4 / Quests / df / AI / State
-- Единственное место, где живёт entity.opts.ai.
--
-- ФИКСЫ:
--   1. ReserveBuildingViaGrid / ReleaseBuildingViaGrid проверяют
--      Grid:IsBuilding(idx). Для не-построек — skip. Иначе SetMoving для
--      tree/earth/grass всегда откатывался в idle.
--   2. SetIdle / Clear сбрасывают entity.nextIndex / posX / posY / step*
--      и зовут UIApi:StopMoving — иначе при сбросе в idle посреди шага
--      остаётся temp-иконка и «висящая» позиция; следующий SetMoving
--      стартует из неверной точки.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local State = {}
    NSQC4.QuestsDfAIState = State
    State.DEBUG = false

    local function dbg(...)
        if State.DEBUG then print("|cff00ffff[STATE]|r", ...) end
    end

    local function GetGrid() return NSQC4.QuestsDfGrid end

    -- ========================================================================
    -- Сброс полей шага + temp-иконки (MoveAnchor).
    -- ========================================================================
    local function ResetStepFields(entity, renderIndex)
        if not entity then return end
        entity.nextIndex     = nil
        entity.posX          = nil
        entity.posY          = nil
        entity.stepStartX    = nil
        entity.stepStartY    = nil
        entity.stepEndX      = nil
        entity.stepEndY      = nil
        entity.stepStartedAt = nil
        entity.stepDuration  = nil

        local EntitiesApi = NSQC4.QuestsDfEntitiesUIApi
        if EntitiesApi and EntitiesApi.StopMoving then
            EntitiesApi:StopMoving(entity, renderIndex or entity.index)
        end
    end

    -- ========================================================================
    -- Резерв постройки (только если это реально постройка).
    -- ========================================================================
    local function ReserveBuildingViaGrid(idx, entity)
        if not idx or not entity then return true end
        local Grid = GetGrid()
        if not Grid then return true end

        if not (Grid.IsBuilding and Grid:IsBuilding(idx)) then
            dbg(string.format("  IsBuilding(%s)=false → ReserveBuilding skip (не постройка)",
                tostring(idx)))
            return true
        end

        if not Grid.ReserveBuilding then
            dbg(string.format("  ReserveBuilding недоступен → skip"))
            return true
        end

        local ok = Grid:ReserveBuilding(idx, entity)
        if ok then
            dbg(string.format("  ReserveBuilding(%s) → ok (%s)",
                tostring(idx), tostring(entity.opts and entity.opts.name)))
        else
            dbg(string.format("  ReserveBuilding(%s) → ЗАНЯТА (%s)",
                tostring(idx), tostring(entity.opts and entity.opts.name)))
        end
        return ok
    end

    -- ========================================================================
    -- Снять резерв постройки (только если это реально постройка).
    -- ========================================================================
    local function ReleaseBuildingViaGrid(idx, entityId)
        if not idx or not entityId then return end
        local Grid = GetGrid()
        if not Grid then return end

        if not (Grid.IsBuilding and Grid:IsBuilding(idx)) then
            dbg(string.format("  IsBuilding(%s)=false → ReleaseBuilding skip", tostring(idx)))
            return
        end

        if not Grid.ReleaseBuilding then return end

        if Grid:ReleaseBuilding(idx, entityId) then
            dbg(string.format("  ReleaseBuilding(%s) → ok (%s)", tostring(idx), tostring(entityId)))
        else
            dbg(string.format("  ReleaseBuilding(%s) → не наш (%s)", tostring(idx), tostring(entityId)))
        end
    end

    -- ========================================================================
    -- Get / состояние
    -- ========================================================================
    function State:Get(entity)
        if not entity or not entity.opts then return nil end
        local ai = entity.opts.ai
        if not ai then
            ai = { state = "idle" }
            entity.opts.ai = ai
            dbg(string.format("Get: создан ai для %s",
                tostring(entity.opts.name or entity.id)))
        end
        if not ai.state then ai.state = "idle" end
        return ai
    end

    -- ========================================================================
    -- carrying
    -- ========================================================================
    function State:SetCarrying(entity, material, count)
        local ai = self:Get(entity)
        if not ai then return false end
        ai.carrying = { material = material, count = count or 1 }
        dbg(string.format("SetCarrying %s material=%s count=%s",
            tostring(entity.opts and entity.opts.name),
            tostring(material), tostring(count or 1)))
        return true
    end

    function State:ClearCarrying(entity)
        local ai = self:Get(entity)
        if ai and ai.carrying then
            dbg(string.format("ClearCarrying %s (was %s x%s)",
                tostring(entity.opts and entity.opts.name),
                tostring(ai.carrying.material), tostring(ai.carrying.count)))
        end
        if ai then ai.carrying = nil end
    end

    function State:GetCarrying(entity)
        local ai = self:Get(entity)
        return ai and ai.carrying or nil
    end

    -- ========================================================================
    -- Clear / SetIdle
    -- ========================================================================
    function State:Clear(entity)
        if not entity or not entity.opts then return end
        local ai = entity.opts.ai
        if not ai then return end

        dbg(string.format("Clear %s old.state=%s old.target=%s",
            tostring(entity.opts.name or entity.id),
            tostring(ai.state), tostring(ai.target)))

        local Grid = GetGrid()
        if ai.target and Grid and Grid.Release then
            Grid:Release(ai.target, entity.id)
            dbg(string.format("  Release(%s) → ok", tostring(ai.target)))
        end

        local bIdx = ai.workTarget or ai.target
        ReleaseBuildingViaGrid(bIdx, entity.id)

        -- ФИКС: сброс полей шага + temp
        ResetStepFields(entity, entity.index)

        entity.opts.ai = nil
    end

    function State:SetIdle(entity)
        if not entity or not entity.opts then return false end
        local old = entity.opts.ai

        dbg("=========================================================")
        dbg(string.format("SetIdle %s old.state=%s old.target=%s",
            tostring(entity.opts.name or entity.id),
            tostring(old and old.state), tostring(old and old.target)))

        if old then
            local Grid = GetGrid()
            if old.target and Grid and Grid.Release then
                Grid:Release(old.target, entity.id)
                dbg(string.format("  Release(%s) → ok", tostring(old.target)))
            end
            local bIdx = old.workTarget or old.target
            ReleaseBuildingViaGrid(bIdx, entity.id)
        end

        -- ФИКС: сброс полей шага + temp, чтобы следующий SetMoving
        -- стартовал из центра текущей клетки, а не из «висящей» точки.
        ResetStepFields(entity, entity.index)

        entity.opts.ai = { state = "idle" }
        dbg("→ state=idle")
        return true
    end

    -- ========================================================================
    -- SetMoving: резерв — только для построек.
    -- ========================================================================
    function State:SetMoving(entity, target, terrainId, profId, path, opts)
        if not entity or not entity.opts then return false end
        if not target or not path or #path == 0 then
            dbg(string.format("SetMoving SKIP: target=%s path=%s len=%s",
                tostring(target), tostring(path ~= nil), tostring(path and #path)))
            return false
        end

        opts = opts or {}
        local wt = opts.workTarget or target

        dbg("=========================================================")
        dbg(string.format("SetMoving %s → target=%s wt=%s terrain=%s prof=%s material=%s",
            tostring(entity.opts.name or entity.id),
            tostring(target), tostring(wt), tostring(terrainId), tostring(profId),
            tostring(opts.material)))
        dbg(string.format("  path len=%d [%s]", #path, table.concat(path, ",")))

        -- снять старый резерв
        local old = entity.opts.ai
        if old then
            local Grid = GetGrid()
            if old.target and old.target ~= target and Grid and Grid.Release then
                Grid:Release(old.target, entity.id)
                dbg(string.format("  Release old.target=%s → ok", tostring(old.target)))
            end
            local oldWork = old.workTarget or old.target
            if oldWork and oldWork ~= wt then
                ReleaseBuildingViaGrid(oldWork, entity.id)
            end
        end

        -- резерв клетки
        local Grid = GetGrid()
        if Grid and Grid.Reserve then
            Grid:Reserve(target, entity.id)
            dbg(string.format("  Reserve(target=%s) → ok", tostring(target)))
        end

        -- резерв постройки (только если wt — реальная постройка)
        if wt then
            local ok = ReserveBuildingViaGrid(wt, entity)
            if not ok then
                if Grid and Grid.Release then
                    Grid:Release(target, entity.id)
                    dbg(string.format("  Release(target=%s) → откат", tostring(target)))
                end
                entity.opts.ai = { state = "idle" }
                dbg(string.format("→ SetMoving FAIL: building %s занята — откат в idle",
                    tostring(wt)))
                return false
            end
        end

        entity.opts.ai = {
            state      = "moving",
            target     = target,
            workTarget = wt,
            terrainId  = terrainId,
            profId     = profId,
            path       = path,
            pathIdx    = 1,
            nextStepAt = GetTime(),
            work       = nil,
            buildWork  = nil,
            carrying   = old and old.carrying or nil,
        }

        -- ФИКС: сброс «висящих» полей шага от предыдущего движения.
        -- Не трогаем posX/posY — Move:Advance их сам пересчитает через
        -- EnsurePos (если nil → центр текущей клетки).
        entity.nextIndex     = nil
        entity.stepStartX    = nil
        entity.stepStartY    = nil
        entity.stepEndX      = nil
        entity.stepEndY      = nil
        entity.stepStartedAt = nil
        entity.stepDuration  = nil

        dbg(string.format("→ state=moving OK (target=%s wt=%s)",
            tostring(target), tostring(wt)))
        return true
    end

    function State:SetWorking(entity)
        if not entity or not entity.opts then return false end
        local ai = self:Get(entity)
        if not ai.target then
            dbg(string.format("SetWorking SKIP: %s — нет target",
                tostring(entity.opts.name or entity.id)))
            return false
        end
        ai.state = "working"
        ai.path = nil
        ai.pathIdx = nil
        ai.nextStepAt = nil
        ai.work = ai.work or {}

        -- сброс полей шага (существо уже в центре целевой клетки)
        entity.nextIndex     = nil
        entity.stepStartX    = nil
        entity.stepStartY    = nil
        entity.stepEndX      = nil
        entity.stepEndY      = nil
        entity.stepStartedAt = nil
        entity.stepDuration  = nil

        dbg(string.format("SetWorking %s at %s",
            tostring(entity.opts.name or entity.id), tostring(ai.target)))
        return true
    end

    function State:IsIdle(entity)
        local ai = self:Get(entity)
        return ai and ai.state == "idle"
    end
    function State:IsMoving(entity)
        local ai = self:Get(entity)
        return ai and ai.state == "moving"
    end
    function State:IsWorking(entity)
        local ai = self:Get(entity)
        return ai and ai.state == "working"
    end

    -- ========================================================================
    -- Слэш-команда
    -- ========================================================================
    SLASH_NSSTATE1 = "/ns_state"
    SlashCmdList["NSSTATE"] = function(msg)
        local cmd, arg = (msg or ""):match("^(%S*)%s*(.-)$")
        cmd = (cmd or ""):lower()
        arg = arg or ""

        if cmd == "" or cmd == "on" then
            State.DEBUG = true
            print("[STATE] DEBUG = true")
        elseif cmd == "off" then
            State.DEBUG = false
            print("[STATE] DEBUG = false")
        elseif cmd == "dump" then
            local Entities = NSQC4.QuestsDfEntities
            if not Entities then
                print("[STATE] dump: Entities не загружен")
                return
            end
            local list = Entities:GetAll()
            print(string.format("[STATE] dump: существ %d", #list))
            for _, e in ipairs(list) do
                local ai = e.opts and e.opts.ai
                if ai then
                    local carrying = ai.carrying
                        and string.format("%s×%d", tostring(ai.carrying.material),
                                                    tonumber(ai.carrying.count) or 1)
                        or "-"
                    print(string.format("  %s idx=%s next=%s state=%s target=%s wt=%s terrain=%s prof=%s pathLen=%s carrying=%s",
                        tostring(e.opts.name or e.id),
                        tostring(e.index),
                        tostring(e.nextIndex),
                        tostring(ai.state),
                        tostring(ai.target),
                        tostring(ai.workTarget),
                        tostring(ai.terrainId),
                        tostring(ai.profId),
                        tostring(ai.path and #ai.path),
                        carrying))
                end
            end
        elseif cmd == "clear" then
            local Entities = NSQC4.QuestsDfEntities
            if not Entities then return end
            if arg ~= "" then
                local e = Entities:GetByName(arg)
                if e then
                    State:SetIdle(e)
                    print("[STATE] clear " .. arg)
                else
                    print("[STATE] не найдено: " .. arg)
                end
            else
                for _, e in ipairs(Entities:GetAll()) do
                    if e.opts then State:SetIdle(e) end
                end
                print("[STATE] clear all")
            end
        else
            print("[STATE] /ns_state on | off | dump | clear [name]")
        end
    end

    print("|cff00ffff[STATE]|r State загружен (DEBUG=" .. tostring(State.DEBUG) .. ")")

end)