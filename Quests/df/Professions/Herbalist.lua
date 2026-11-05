-- ============================================================================
-- NSQC4 / Quests / df / Professions / Herbalist
-- Профессия «Травник». Собирает травы (grass).
--
-- Профессия — самостоятельная единица. Знает:
--   - к каким объектам применяется (terrain)
--   - каким параметром существа ускоряется (stat) — ИНТЕЛЛЕКТ
--   - как считать клики под конкретный объект (clicks)
--   - что даёт по завершении (work.yields)
--
-- Формула кликов — ВНУТРИ профессии:
--   factor = 1 − 0.666 × prof_pct − 0.333 × stat_pct
--   clicks = max(1, round(hardness × factor))
--
--   prof_pct — уровень травника / 100
--   stat_pct — интеллект / максимум (Resolve:StatPct(entity, "intellect"))
--
-- hardness берётся из df/Terrain/Data/Grass.lua (100).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local P = NSQC4.QuestsDfProfessionsApi
    if not P then
        print("|cffff0000[NSQC4]|r Herbalist: Professions/Init.lua не загружен.")
        return
    end

    -- Веса вклада в снижение кликов (в сумме 0.999).
    local PROF_WEIGHT = 0.666
    local STAT_WEIGHT = 0.333

    -- ========================================================================
    -- Формула кликов Травника.
    --   hardness — базовое HP объекта (из Terrain/Data)
    --   prof_pct — 0..1 (насколько прокачана профессия)
    --   stat_pct — 0..1 (интеллект существа / максимум)
    -- Возвращает целое ≥ 1.
    -- ========================================================================
    local function clicks(hardness, prof_pct, stat_pct)
        hardness = tonumber(hardness) or 0
        if hardness <= 0 then return 1 end

        prof_pct = tonumber(prof_pct) or 0
        stat_pct = tonumber(stat_pct) or 0
        if prof_pct < 0 then prof_pct = 0 elseif prof_pct > 1 then prof_pct = 1 end
        if stat_pct < 0 then stat_pct = 0 elseif stat_pct > 1 then stat_pct = 1 end

        local factor = 1 - PROF_WEIGHT * prof_pct - STAT_WEIGHT * stat_pct
        if factor < 0 then factor = 0 end

        local n = math.floor(hardness * factor + 0.5)
        if n < 1 then n = 1 end
        return n
    end

    -- ========================================================================
    -- Регистрация профессии.
    -- ========================================================================
    P:Register("herbalist", {
        name    = "Травник",
        desc    = "Собирает травы, ягоды, грибы.",
        terrain = "grass",          -- к какому объекту применяется
        stat    = "intellect",      -- какой параметр ускоряет (интеллект)
        clicks  = clicks,           -- формула кликов (внутри профессии)
        work    = { verb = "собирает", duration = 1, yields = "herbs" },
    })

end)