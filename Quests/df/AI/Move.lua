-- ============================================================================
-- NSQC4 / Quests / df / AI / Move
-- Передвижение существа по маршруту. Скорость — по абсолютной выносливости.
--
-- stepTime = 100 − 99 × (vitality / 100)
--   vitality 0/1     → ~100–99 сек/клетку
--   vitality 100     → 1 сек/клетку
--
-- При каждом шаге — шанс прокачки живучести (intellect / 100).
--
-- Отладка: /run NSQC4.QuestsDfAIMove.DEBUG = true
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

    -- ========================================================================
    -- Время на один шаг (секунды) по АБСОЛЮТНОЙ выносливости (0..100).
    -- max_vitality не используется.
    -- ========================================================================
    function Move:StepTime(entity)
        if not entity or not entity.opts then return 100 end
        local opts = entity.opts

        local vit = tonumber(opts.vitality) or 0
        local pct = vit / 100
        if pct < 0 then pct = 0 elseif pct > 1 then pct = 1 end

        local t = 100 - 99 * pct

        dbg(string.format("step %s vit=%s pct=%.3f stepTime=%.2fs",
            tostring(entity.id), tostring(vit), pct, t))
        return t
    end

    -- ========================================================================
    -- Один шаг по маршруту.
    -- ========================================================================
    function Move:Advance(entity)
        if not entity or not entity.opts then return nil end

        local ai = entity.opts.ai
        if not ai or not ai.path or not ai.pathIdx then return nil end

        local path = ai.path
        local idx  = ai.pathIdx

        if idx >= #path then
            return "arrived"
        end

        local now = GetTime()
        if ai.nextStepAt and now < ai.nextStepAt then
            dbg(string.format("wait %s now=%.2f nextStepAt=%.2f left=%.2fs",
                tostring(entity.id), now, ai.nextStepAt, ai.nextStepAt - now))
            return "wait"
        end

        local nextIndex = path[idx + 1]
        if not nextIndex then return nil end

        local isTarget = (idx + 1 == #path)
        if not isTarget and not Grid:IsPassable(nextIndex) then
            dbg(string.format("blocked %s next=%d", tostring(entity.id), nextIndex))
            ai.path = nil
            ai.pathIdx = nil
            return nil
        end

        local fromIndex = entity.index
        local stepTime  = self:StepTime(entity)

        -- 1. Данные
        Grid:SetEntity(fromIndex, nil)
        entity.index = nextIndex
        Grid:SetEntity(nextIndex, entity)

        -- 2. Анимация
        local Animate = NSQC4.QuestsDfEntitiesAnimate
        if Animate and fromIndex and nextIndex then
            Animate:Start(entity.id, {
                icon     = entity.opts.icon or entity.opts.texture,
                anchor   = "TOPLEFT",
                expanded = entity.opts.expanded,
                alpha    = entity.opts.alpha,
            }, fromIndex, nextIndex, stepTime)
        end

        -- 3. Путь и таймер
        ai.pathIdx    = idx + 1
        ai.nextStepAt = now + stepTime

        -- 4. Прокачка живучести при шаге
        local Stats = NSQC4.QuestsDfAIStats
        if Stats and Stats.TryUpVitality then
            Stats:TryUpVitality(entity)
        end

        dbg(string.format("move %s %d -> %d  stepTime=%.2fs",
            tostring(entity.id), fromIndex or 0, nextIndex, stepTime))

        if ai.pathIdx >= #path then
            return "arrived"
        end
        return "moved"
    end

end)