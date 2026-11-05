-- ============================================================================
-- NSQC4 / Quests / df / Professions / Builder
-- Профессия «Строитель». Строит и ломает лестницы (ladder).
--
-- terrain = "ladder", stat = "agility" (ловкость).
-- clicks(hardness, prof_pct, stat_pct) — та же формула, что у Лесоруба:
--   factor = 1 - 0.666 * prof_pct - 0.333 * stat_pct
--   clicks = max(1, round(hardness * factor))
--
-- Регистрируется в ProfessionsApi под id "builder", имя "Строитель".
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local P = NSQC4.QuestsDfProfessionsApi
    if not P then
        print("|cffff0000[NSQC4]|r Builder: Professions/Init.lua не загружен.")
        return
    end

    local PROF_WEIGHT = 0.666
    local STAT_WEIGHT = 0.333

    -- ========================================================================
    -- Формула кликов Строителя (стройка И лом).
    --   hardness — сколько HP нужно построить/сломать (например, 1000)
    --   prof_pct — уровень Строителя / 100
    --   stat_pct — ловкость / максимум
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
    P:Register("builder", {
        name    = "Строитель",
        desc    = "Строит и ломает лестницы.",
        terrain = "ladder",
        stat    = "agility",
        clicks  = clicks,
        work    = { verb = "строит", duration = 1, yields = nil },
    })

end)