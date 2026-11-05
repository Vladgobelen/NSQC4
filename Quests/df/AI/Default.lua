-- ============================================================================
-- NSQC4 / Quests / df / AI / Default
-- Общий fallback-цикл поведения существа: idle → moving → working.
--
-- При idle→moving — звук по kind существа (gob.ogg / gom.ogg).
--
-- Path:Find вызывается с entity — чтобы вода была проходима только
-- для существ с профессией «Пловец» (Resolve:CanSwim).
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

    local function IsTargetStillSelected(entity)
        local ai = entity and entity.opts and entity.opts.ai
        if not ai or not ai.target or not ai.terrainId then return false end
        local Grid = NSQC4.QuestsDfGrid
        if not Grid then return true end
        return Grid:IsTerrainSelected(ai.target, ai.terrainId) and true or false
    end

    function Default:Tick(entity)
        if not entity or not entity.opts then return false end
        if entity.opts.sleeping then return false end

        local ai = entity.opts.ai
        if ai and ai.target and (ai.state == "moving" or ai.state == "working") then
            if not IsTargetStillSelected(entity) then
                dbg("drop target", ai.target, "terrain", ai.terrainId,
                    "state", ai.state, "entity", entity.id)

                local Animate = NSQC4.QuestsDfEntitiesAnimate
                if Animate and Animate:IsAnimating(entity.id) then
                    Animate:Stop(entity.id)
                end
                State:SetIdle(entity)
                return true
            end
        end

        if State:IsIdle(entity) then
            local pick = Find:Pick(entity)
            if not pick then return false end

            -- entity передаём третьим параметром:
            -- вода проходима только для пловца (Resolve:CanSwim).
            local path = Path:Find(entity.index, pick.index, entity)
            if not path then return false end

            State:SetMoving(entity, pick.index, pick.terrainId, pick.profId, path)
            dbg("idle→moving", entity.id, "->", pick.index, pick.terrainId)

            local Sound = NSQC4.QuestsDfAISound
            if Sound then
                Sound:PlayKind(entity.kind or entity.opts.kind)
            end
            return true
        end

        if State:IsMoving(entity) then
            local r = Move:Advance(entity)
            if r == "arrived" then
                State:SetWorking(entity)
                dbg("moving→working", entity.id)
                return true
            elseif r == "moved" or r == "wait" then
                return true
            else
                State:SetIdle(entity)
                return false
            end
        end

        if State:IsWorking(entity) then
            local done = Work:Tick(entity)
            if done == true then
                Complete:Finish(entity)
                dbg("work done", entity.id)
                return true
            elseif done == false then
                return true
            else
                State:SetIdle(entity)
                return false
            end
        end

        State:SetIdle(entity)
        return false
    end

end)