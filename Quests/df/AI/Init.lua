-- ============================================================================
-- NSQC4 / Quests / df / AI / Init
-- Точка входа подмодуля AI существ.
--
-- Namespace: NSQC4.QuestsDfAI
-- Константы тика: INTERVAL = 1.0 сек.
--
-- Сюда позже придут:
--   df/AI/State.lua    — opts.ai (state/path/target/work)
--   df/AI/Find.lua     — поиск цели по выделенным + Allowed
--   df/AI/Path.lua     — BFS-маршрут
--   df/AI/Move.lua     — шаг по пути
--   df/AI/Work.lua     — клик по hardness
--   df/AI/Complete.lua — завершение работы на клетке
--   df/AI/Tick.lua     — один тик для одного существа
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local AI = {}
    NSQC4.QuestsDfAI = AI

    -- Интервал тика (секунды).
    AI.INTERVAL = 1.0

    -- ========================================================================
    -- Один тик для одного существа.
    -- Пока — заглушка. Наполним, когда появятся State/Find/Path/Move/Work.
    -- ========================================================================
    function AI:TickEntity(entity)
        -- TODO: idle → поиск цели → moving → working
        return false
    end

end)