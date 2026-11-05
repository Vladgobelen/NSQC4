-- ============================================================================
-- NSQC4 / Quests / df / Professions / Digger
-- Профессия «Диггер». Копает землю (earth).
--
-- Профессия — самостоятельная единица. Знает:
--   - к каким объектам применяется (terrain)
--   - каким параметром существа ускоряется (stat)
--   - как считать клики под конкретный объект (clicks)
--   - что даёт по завершении (work.yields)
--
-- Формула кликов — ВНУТРИ профессии. Другие профессии могут считать иначе.
-- Позже сюда добавим скорость прокачки (зависит от интеллекта и т.п.).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local P = NSQC4.QuestsDfProfessionsApi
    if not P then
        print("|cffff0000[NSQC4]|r Digger: Professions/Init.lua не загружен.")
        return
    end

    -- Веса вклада в снижение кликов (в сумме 0.999).
    local PROF_WEIGHT = 0.666
    local STR_WEIGHT  = 0.333

    -- ========================================================================
    -- Формула кликов Диггера.
    --   hardness — базовое HP объекта (из Terrain/Data)
    --   prof_pct — 0..1 (насколько прокачана профессия)
    --   str_pct  — 0..1 (сила существа / максимум)
    -- Возвращает целое ≥ 1.
    -- ========================================================================
    local function clicks(hardness, prof_pct, str_pct)
        hardness = tonumber(hardness) or 0
        if hardness <= 0 then return 1 end

        prof_pct = tonumber(prof_pct) or 0
        str_pct  = tonumber(str_pct)  or 0
        if prof_pct < 0 then prof_pct = 0 elseif prof_pct > 1 then prof_pct = 1 end
        if str_pct  < 0 then str_pct  = 0 elseif str_pct  > 1 then str_pct  = 1 end

        local factor = 1 - PROF_WEIGHT * prof_pct - STR_WEIGHT * str_pct
        if factor < 0 then factor = 0 end

        local n = math.floor(hardness * factor + 0.5)
        if n < 1 then n = 1 end
        return n
    end

    -- ========================================================================
    -- Регистрация профессии.
    -- ========================================================================
    P:Register("digger", {
        name    = "Диггер",
        desc    = "Копает землю, добывает глину.",
        terrain = "earth",          -- к какому объекту применяется
        stat    = "strength",       -- какой параметр ускоряет
        clicks  = clicks,           -- формула кликов (внутри профессии)
        work    = { verb = "копает", duration = 1, yields = "clay" },
    })

end)