-- ============================================================================
-- NSQC4 / Quests / df / AI / Tick
-- Диспетчер поведения существ.
--
-- Вызывается из Ticker:Tick() через AI:TickEntity(entity).
-- Смотрит kind + behavior, ищет Behavior[kind][behavior]:Tick.
-- Если нет — Default:Tick(entity).
--
-- Сам ничего не делает: ни поиска, ни пути, ни работы.
-- Только выбирает, чьё поведение выполнять.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local AI = NSQC4.QuestsDfAI
    if not AI then
        print("|cffff0000[NSQC4]|r AI/Tick: AI/Init.lua не загружен.")
        return
    end

    local Default = NSQC4.QuestsDfAIDefault
    if not Default then
        print("|cffff0000[NSQC4]|r AI/Tick: AI/Default.lua не загружен.")
        return
    end

    -- Переопределяем заглушку из AI/Init.lua.
    function AI:TickEntity(entity)
        if not entity or not entity.opts then return false end

        local kind     = entity.kind or entity.opts.kind
        local behavior = entity.opts.behavior or "peaceful"

        -- Прямой поиск: Behavior[kind][behavior]:Tick
        local Registry = NSQC4.QuestsDfBehavior
        local byKind   = Registry and kind and Registry[kind]
        local handler  = byKind and byKind[behavior]

        if handler and handler.Tick then
            return handler.Tick(entity)
        end

        -- Fallback
        return Default:Tick(entity)
    end

end)