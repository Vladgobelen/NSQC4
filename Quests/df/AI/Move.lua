-- ============================================================================
-- NSQC4 / Quests / df / AI / Move
-- Движение от штатной точки к штатной точке.
--
-- ШТАТНЫЕ ТОЧКИ (единое правило, GetAnchorPos):
--   свёрнутая  (expanded=false) — TOPLEFT + ins + size/2   (верхний левый угол)
--   развёрнутая (expanded=true) — центр клетки
--
-- ЕДИНЫЙ ИСТОЧНИК ИСТИНЫ:
--   entity.posX / entity.posY — позиция в координатах поля.
--   entity.opts.expanded      — флаг размера.
--   Текстура (temp/anchor) — чистая функция от них (см. Entities/UI/Api).
--
-- СМЕНА expanded В ПУТИ:
--   Пересчитываем stepStart/stepEnd по новому expanded и корректируем
--   stepStartedAt так, чтобы posX/posY в момент смены не изменились.
--
-- ЗАВЕРШЕНИЕ ШАГА (t >= 1):
--   ПОРЯДОК ВАЖЕН: сначала обновляем данные (entity.index, posX/posY,
--   ResetStep, Grid:SetEntityName), ПОТОМ один раз перерисовываем.
--   Раньше StopMoving(to) звался ДО SetEntityName(to) — Api:Render для `to`
--   не находил существа и рисовал пустую клетку → иконка «пропадала на
--   секунду» до следующего тика. Теперь — нет.
--
-- stepTime = 100 − 99 × (vitality / 100)  секунд на клетку.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Move = {}
    NSQC4.QuestsDfAIMove = Move
    Move.DEBUG = false

    local function dbg(...)
        if Move.DEBUG then print("|cff00ffff[MOVE]|r", ...) end
    end

    local Grid = NSQC4.QuestsDfGrid
    if not Grid then
        print("|cffff0000[NSQC4]|r AI/Move: Grid не загружен.")
        return
    end

    local QuestsField = NSQC4.QuestsField

    function Move:StepTime(entity)
        if not entity or not entity.opts then return 100 end
        local vit = tonumber(entity.opts.vitality) or 0
        local pct = vit / 100
        if pct < 0 then pct = 0 elseif pct > 1 then pct = 1 end
        return 100 - 99 * pct
    end

    local function CanStepInto(nextIndex, entity)
        local c = Grid:GetCell(nextIndex)
        if not c then return false end
        if c.terrain == "void" then return false end
        if c.terrain == "water" then
            local Resolve = NSQC4.QuestsDfProfessionsResolve
            local canSwim = Resolve and Resolve.CanSwim and Resolve:CanSwim(entity) or false
            if not canSwim then return false end
        end
        if c.entityName then
            local me = entity.opts and entity.opts.name
            if not me or c.entityName ~= me then return false end
        end
        return true
    end

    function Move:ResetStep(entity)
        if not entity then return end
        entity.nextIndex     = nil
        entity.stepStartX    = nil; entity.stepStartY = nil
        entity.stepEndX      = nil; entity.stepEndY   = nil
        entity.stepStartedAt = nil; entity.stepDuration = nil
        entity.stepExpanded  = nil
    end

    local function IsExpanded(entity)
        return entity and entity.opts and entity.opts.expanded and true or false
    end

    -- ========================================================================
    -- Зафиксировать начало шага: точки старта/финиша по ТЕКУЩЕМУ expanded.
    -- ========================================================================
    local function BeginStep(entity, nextIndex, expanded)
        local sX, sY = QuestsField:GetAnchorPos(entity.index, expanded)
        local eX, eY = QuestsField:GetAnchorPos(nextIndex, expanded)
        if not sX or not eX then return false end

        local EntitiesApi = NSQC4.QuestsDfEntitiesUIApi
        if EntitiesApi and EntitiesApi.HideAnchorAt then
            EntitiesApi:HideAnchorAt(entity.index)
        end

        entity.nextIndex     = nextIndex
        entity.stepStartX    = sX
        entity.stepStartY    = sY
        entity.stepEndX      = eX
        entity.stepEndY      = eY
        entity.stepStartedAt = GetTime()
        entity.stepDuration  = Move:StepTime(entity)
        entity.stepExpanded  = expanded
        entity.posX          = sX
        entity.posY          = sY
        return true
    end

    -- ========================================================================
    -- Пересчитать штатные точки шага под НОВЫЙ expanded, сохранив
    -- текущую позицию posX/posY и долю прохождения t.
    -- ========================================================================
    local function RebaseStepForExpanded(entity, expanded)
        if not entity.nextIndex then return end
        if not entity.stepStartX then return end

        local Px, Py = entity.posX, entity.posY
        if not Px or not Py then return end

        local sX, sY = QuestsField:GetAnchorPos(entity.index, expanded)
        local eX, eY = QuestsField:GetAnchorPos(entity.nextIndex, expanded)
        if not sX or not eX then return end

        local dx, dy = (eX - sX), (eY - sY)
        local len2 = dx * dx + dy * dy

        local tNew
        if len2 <= 0.0001 then
            tNew = 0
            entity.posX = sX
            entity.posY = sY
        else
            local tRaw = ((Px - sX) * dx + (Py - sY) * dy) / len2
            if tRaw < 0 then tRaw = 0 elseif tRaw > 1 then tRaw = 1 end
            tNew = tRaw
        end

        local now = GetTime()
        local dur = entity.stepDuration or 1
        if dur <= 0 then dur = 1 end

        entity.stepStartX    = sX
        entity.stepStartY    = sY
        entity.stepEndX      = eX
        entity.stepEndY      = eY
        entity.stepStartedAt = now - tNew * dur

        entity.posX = sX + (eX - sX) * tNew
        entity.posY = sY + (eY - sY) * tNew

        dbg(string.format("rebase expanded=%s t=%.3f pos=(%.1f,%.1f)",
            tostring(expanded), tNew, entity.posX, entity.posY))
    end

    function Move:SyncExpanded(entity)
        if not entity or not entity.nextIndex then return false end
        RebaseStepForExpanded(entity, IsExpanded(entity))
        return true
    end

    function Move:Advance(entity)
        if not entity or not entity.opts then return nil end
        local ai = entity.opts.ai
        if not ai or not ai.path or not ai.pathIdx then return nil end
        if not ai.target then
            ai.path = nil; ai.pathIdx = nil
            return nil
        end

        local path = ai.path
        local name = entity.opts.name or entity.id
        local now  = GetTime()
        local EntitiesApi = NSQC4.QuestsDfEntitiesUIApi

        -- --------------------------------------------------------------
        -- Старт нового шага
        -- --------------------------------------------------------------
        if not entity.nextIndex then
            if ai.pathIdx >= #path then return "arrived" end
            if ai.nextStepAt and now < ai.nextStepAt then return "wait" end

            local nxt = path[ai.pathIdx + 1]
            if not nxt then return nil end
            if not CanStepInto(nxt, entity) then
                ai.path = nil; ai.pathIdx = nil
                return nil
            end

            local expanded = IsExpanded(entity)
            if not BeginStep(entity, nxt, expanded) then return nil end

            dbg(string.format("%s: start %s → %s exp=%s dur=%.2f",
                tostring(name), tostring(entity.index), tostring(nxt),
                tostring(expanded), entity.stepDuration))
        end

        -- --------------------------------------------------------------
        -- СМЕНА expanded В ПУТИ: если флаг разошёлся с геометрией шага —
        -- пересчитать концы и t без рывка.
        -- --------------------------------------------------------------
        local curExpanded = IsExpanded(entity)
        if entity.stepExpanded ~= curExpanded then
            RebaseStepForExpanded(entity, curExpanded)
            entity.stepExpanded = curExpanded
        end

        local t = (now - entity.stepStartedAt) / entity.stepDuration
        if t >= 1 then t = 1 end

        local x = entity.stepStartX + (entity.stepEndX - entity.stepStartX) * t
        local y = entity.stepStartY + (entity.stepEndY - entity.stepStartY) * t
        entity.posX = x
        entity.posY = y

        if EntitiesApi and EntitiesApi.MoveAnchor then
            EntitiesApi:MoveAnchor(entity, x, y)
        end

        -- --------------------------------------------------------------
        -- ЗАВЕРШЕНИЕ ШАГА
        -- Порядок: СНАЧАЛА данные, ПОТОМ рендер.
        -- --------------------------------------------------------------
        if t >= 1 then
            local from = entity.index
            local to   = entity.nextIndex

            -- 1. Данные: позиция, сброс шага, имена в Grid.
            entity.index = to
            entity.posX  = entity.stepEndX
            entity.posY  = entity.stepEndY
            self:ResetStep(entity)   -- nextIndex=nil, step*=nil, stepExpanded=nil

            Grid:SetEntityName(from, nil)
            Grid:SetEntityName(to, entity.opts and entity.opts.name)

            ai.pathIdx    = ai.pathIdx + 1
            ai.nextStepAt = nil

            -- 2. Рендер: StopMoving видит согласованное состояние
            --    (entity.index=to, nextIndex=nil, Grid:GetEntity(to)=entity)
            --    и рисует anchor в `to`, а не пустую клетку.
            if EntitiesApi and EntitiesApi.StopMoving then
                EntitiesApi:StopMoving(entity, to)
            end
            -- `from` гарантированно очистить (на случай, если там остался
            -- temp/anchor от предыдущего шага).
            if EntitiesApi and EntitiesApi.RenderCellFromStorage then
                EntitiesApi:RenderCellFromStorage(from)
            end

            local Stats = NSQC4.QuestsDfAIStats
            if Stats and Stats.TryUpVitality then Stats:TryUpVitality(entity) end

            if ai.pathIdx >= #path then return "arrived" end
            return "moved"
        end

        return "moving"
    end

    SLASH_NSMOVE1 = "/ns_move"
    SlashCmdList["NSMOVE"] = function(msg)
        local cmd = (msg or ""):lower():match("^(%S*)")
        if cmd == "" or cmd == "on" then Move.DEBUG = true; print("[MOVE] DEBUG = true")
        elseif cmd == "off" then Move.DEBUG = false; print("[MOVE] DEBUG = false")
        elseif cmd == "dump" then
            local Entities = NSQC4.QuestsDfEntities
            if not Entities then return end
            for _, e in ipairs(Entities:GetAll()) do
                local ai = e.opts and e.opts.ai
                if ai then
                    print(string.format("[MOVE] %s idx=%s next=%s pos=(%.1f,%.1f) exp=%s state=%s",
                        tostring(e.opts.name), tostring(e.index), tostring(e.nextIndex),
                        e.posX or -1, e.posY or -1, tostring(e.opts.expanded), tostring(ai.state)))
                end
            end
        else print("[MOVE] /ns_move on | off | dump") end
    end

    print("|cff00ffff[MOVE]|r Move загружен (штатные точки, rebase при смене expanded, без пропадания на финише)")
end)