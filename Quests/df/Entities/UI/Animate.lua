-- ============================================================================
-- NSQC4 / Quests / df / Entities / UI / Animate
-- Тонкая обёртка над Entities/UI/Api. НЕ ведёт свою интерполяцию.
--
-- ПОЧЕМУ:
--   Раньше Animate был вторым независимым интегратором позиции: он двигал
--   temp по своим from/to и своему t, а Move в это же время двигал ту же
--   temp по posX/posY. Два источника — рывки и «не туда».
--
-- ТЕПЕРЬ:
--   Единственный интегратор — Move:Advance (пишет entity.posX/posY).
--   Единственный рендер — Entities/UI/Api (RefreshTempAt / Render).
--   Animate отвечает только за:
--     - флаг «существо в движении» (IsAnimating),
--     - смену expanded во время движения (через Move:SyncExpanded),
--     - Stop/StopAll (сброс временных текстур — на самом деле это делает Api).
--
-- Совместимость: старые вызовы Animate:Start(id, opts, from, to, dur)
-- не используются новым кодом (Move сам стартует шаг). Оставлены как
-- no-op / прокси к Api, чтобы не падали старые места, если где-то ещё
-- зовут Start/Stop.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Animate = {}
    NSQC4.QuestsDfEntitiesAnimate = Animate

    Animate.DEBUG = false

    local function dbg(...)
        if Animate.DEBUG then print("|cff00ffff[ANIM]|r", ...) end
    end

    local QuestsField = NSQC4.QuestsField
    if not QuestsField then
        print("|cffff0000[NSQC4]|r Animate: поле не загружено.")
        return
    end

    local Api = NSQC4.QuestsDfEntitiesUIApi

    -- ========================================================================
    -- IsAnimating: существо в пути?
    --   Определяется по entity.nextIndex (Move выставил) — это и есть
    --   «в движении». Не по внутренней таблице Animate.
    -- ========================================================================
    function Animate:IsAnimating(id)
        if not id then return false end
        local Entities = NSQC4.QuestsDfEntities
        if not Entities then return false end
        local entity = Entities:Get(id)
        if not entity then return false end
        return entity.nextIndex ~= nil
    end

    -- ========================================================================
    -- SetExpanded: сменить флаг размера во время движения.
    --   Делегируем в Move:SyncExpanded — он пересчитает концы шага и
    --   скорректирует t, чтобы posX/posY не прыгнули. Затем — перерисовать
    --   temp по новой геометрии через Api.
    -- ========================================================================
    function Animate:SetExpanded(id, expanded)
        local Entities = NSQC4.QuestsDfEntities
        if not Entities then return false end
        local entity = Entities:Get(id)
        if not entity then return false end

        entity.opts.expanded = expanded and true or false

        -- если в пути — пересчитать геометрию шага без рывка
        local Move = NSQC4.QuestsDfAIMove
        if Move and Move.SyncExpanded and entity.nextIndex then
            Move:SyncExpanded(entity)
        end

        -- перерисовать: Api сам разберётся (temp в пути / anchor в покое)
        if Api and Api.RenderCellFromStorage then
            Api:RenderCellFromStorage(entity.index)
        end

        dbg("SetExpanded", tostring(id), tostring(expanded))
        return true
    end

    -- ========================================================================
    -- Stop: сбросить «временную» текстуру существа и перерисовать клетку.
    --   Реально это делает Api:StopMoving / RenderCellFromStorage.
    -- ========================================================================
    function Animate:Stop(id)
        local Entities = NSQC4.QuestsDfEntities
        if not Entities then return false end
        local entity = Entities:Get(id)
        if not entity then return false end

        local index = entity.nextIndex or entity.index
        if Api and Api.StopMoving then
            Api:StopMoving(entity, index)
        elseif Api and Api.RenderCellFromStorage then
            Api:RenderCellFromStorage(entity.index)
        end

        dbg("Stop", tostring(id))
        return true
    end

    -- ========================================================================
    -- StopAll: остановить все «временные» текстуры существ.
    -- ========================================================================
    function Animate:StopAll()
        local Entities = NSQC4.QuestsDfEntities
        if not Entities then return 0 end
        local n = 0
        for _, e in ipairs(Entities:GetAll()) do
            if e.id and e.nextIndex then
                self:Stop(e.id)
                n = n + 1
            end
        end
        dbg("StopAll:", n)
        return n
    end

    -- ========================================================================
    -- Start: СОВМЕСТИМОСТЬ.
    --   Новый код не должен звать Start — шаг стартует Move:Advance.
    --   Если где-то остался старый вызов — просто перерисуем клетку и
    --   вернём true, чтобы не падало.
    -- ========================================================================
    function Animate:Start(id, opts, fromIndex, toIndex, duration)
        if Animate.DEBUG then
            print(string.format("[ANIM] Start(%s) — устаревший вызов, перерисовка клетки %s",
                tostring(id), tostring(toIndex)))
        end
        if Api and Api.RenderCellFromStorage and toIndex then
            Api:RenderCellFromStorage(toIndex)
        end
        return true
    end

    -- ========================================================================
    -- Tick: пусто. Интерполяцию ведёт Move:Advance (вызывается из AI:Tick).
    --   Оставлено для совместимости (кто-то мог дёргать Animate:Tick).
    -- ========================================================================
    function Animate:Tick()
        -- no-op
    end

    -- ========================================================================
    -- Dump: диагностика.
    -- ========================================================================
    function Animate:Dump()
        local Entities = NSQC4.QuestsDfEntities
        if not Entities then
            print("[ANIM] Entities не загружен")
            return
        end
        local n = 0
        for _, e in ipairs(Entities:GetAll()) do
            if e.nextIndex then
                n = n + 1
                print(string.format("[ANIM] %s: %s→%s pos=(%.1f,%.1f) exp=%s",
                    tostring(e.id), tostring(e.index), tostring(e.nextIndex),
                    e.posX or -1, e.posY or -1, tostring(e.opts and e.opts.expanded)))
            end
        end
        print("[ANIM] в движении:", n)
    end

    print("|cff00ffff[ANIM]|r Animate загружен (тонкая обёртка над Api, без своей интерполяции)")
end)