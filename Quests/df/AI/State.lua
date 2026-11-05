-- ============================================================================
-- NSQC4 / Quests / df / AI / State
-- Единственное место, где живёт и меняется entity.opts.ai.
--
-- Резерв клетки:
--   SetMoving(entity, target, …)  → Grid:Reserve(target, entity.id)
--   SetIdle(entity)               → Grid:Release(old.target, entity.id)
--   Clear(entity)                 → Grid:Release(old.target, entity.id)
--   SetWorking(entity)            → ничего (резерв уже стоит с SetMoving)
--
-- Формат opts.ai:
--   { state, target, terrainId, profId, path, pathIdx, nextStepAt, work }
--
-- API:
--   Get, Clear, SetIdle, SetMoving, SetWorking,
--   IsIdle, IsMoving, IsWorking
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local State = {}
    NSQC4.QuestsDfAIState = State

    State.DEBUG = false

    local function dbg(...)
        if State.DEBUG then print("|cff00ffff[STATE]|r", ...) end
    end

    local function GetGrid()
        return NSQC4.QuestsDfGrid
    end

    -- ========================================================================
    -- Получить opts.ai (создать «idle» при первом обращении).
    -- ========================================================================
    function State:Get(entity)
        if not entity or not entity.opts then return nil end
        local ai = entity.opts.ai
        if not ai then
            ai = { state = "idle" }
            entity.opts.ai = ai
        end
        if not ai.state then ai.state = "idle" end
        return ai
    end

    -- ========================================================================
    -- Сбросить всё (с освобождением резерва).
    -- ========================================================================
    function State:Clear(entity)
        if not entity or not entity.opts then return end
        local ai = entity.opts.ai
        if ai and ai.target then
            local Grid = GetGrid()
            if Grid and Grid.Release then
                Grid:Release(ai.target, entity.id)
            end
            dbg("Clear: release", ai.target, tostring(entity.id))
        end
        entity.opts.ai = nil
    end

    -- ========================================================================
    -- idle: цель/путь/работа сброшены, резерв снят.
    -- ========================================================================
    function State:SetIdle(entity)
        if not entity or not entity.opts then return false end
        local old = entity.opts.ai
        if old and old.target then
            local Grid = GetGrid()
            if Grid and Grid.Release then
                Grid:Release(old.target, entity.id)
            end
            dbg("SetIdle: release", old.target, tostring(entity.id))
        end
        entity.opts.ai = { state = "idle" }
        return true
    end

    -- ========================================================================
    -- moving: цель + маршрут + резерв клетки.
    -- ========================================================================
    function State:SetMoving(entity, target, terrainId, profId, path)
        if not entity or not entity.opts then return false end
        if not target or not path or #path == 0 then return false end

        -- Освободить старый резерв, если был
        local old = entity.opts.ai
        if old and old.target and old.target ~= target then
            local Grid = GetGrid()
            if Grid and Grid.Release then
                Grid:Release(old.target, entity.id)
            end
        end

        entity.opts.ai = {
            state      = "moving",
            target     = target,
            terrainId  = terrainId,
            profId     = profId,
            path       = path,
            pathIdx    = 1,
            nextStepAt = GetTime(),
            work       = nil,
        }

        local Grid = GetGrid()
        if Grid and Grid.Reserve then
            Grid:Reserve(target, entity.id)
        end
        dbg("SetMoving", tostring(entity.id), "->", target, tostring(terrainId), tostring(profId))
        return true
    end

    -- ========================================================================
    -- working: дошли до цели, путь не нужен. Резерв остаётся.
    -- ========================================================================
    function State:SetWorking(entity)
        if not entity or not entity.opts then return false end
        local ai = self:Get(entity)
        if not ai.target then return false end

        ai.state      = "working"
        ai.path       = nil
        ai.pathIdx    = nil
        ai.nextStepAt = nil
        ai.work       = ai.work or {}
        dbg("SetWorking", tostring(entity.id), "at", ai.target)
        return true
    end

    -- ========================================================================
    -- Проверки
    -- ========================================================================
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

end)