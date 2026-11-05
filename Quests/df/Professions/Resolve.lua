-- ============================================================================
-- NSQC4 / Quests / df / Professions / Resolve
-- Перевод данных существа в числа, которые ждёт формула профессии,
-- + проверка «умеет ли существо плавать» (для воды).
--
-- Формула любой профессии принимает:
--   clicks(hardness, prof_pct, stat_pct)
--
-- Resolve готовит два числа:
--   prof_pct — насколько прокачана «своя» профессия для данного terrain (0..1)
--   stat_pct — профильный стат существа относительно максимума (0..1):
--                "strength"  → opts.strength  / opts.max_strength
--                "agility"   → opts.agility   / opts.max_agility
--                "intellect" → opts.intellect / opts.max_intellect
--
-- Откуда берёт:
--   prof_pct:
--     opts.known_skills — таблица [имя] = уровень (1..100)
--     → ProfessionsApi:GetByName(name) → def.terrain == terrainId
--     → уровень / 100 = 0..1
--   stat_pct:
--     Resolve:StatPct(entity, stat), где stat — profDef.stat
--
-- CanSwim(entity):
--   true, если у существа есть ЛЮБАЯ профессия с terrain == "water"
--   (сейчас — "Пловец"). Вода пересекается только пловцами.
--   Используется в AI/Path.lua (Path:Find) и AI/Move.lua (CanStepInto).
--
-- Ничего не знает про Grid, движение, работу, клики.
-- Только entity + terrainId (+ stat) → числа / булево.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Resolve = {}
    NSQC4.QuestsDfProfessionsResolve = Resolve

    -- ========================================================================
    -- prof_pct: 0..1.
    --   0 — нет подходящей профессии для этого terrain (или уровень 0).
    -- ========================================================================
    function Resolve:ProfPct(entity, terrainId)
        if not entity or not entity.opts then return 0 end
        if type(terrainId) ~= "string" or terrainId == "" then return 0 end

        local opts = entity.opts
        local ProfApi = NSQC4.QuestsDfProfessionsApi
        if not ProfApi or type(opts.known_skills) ~= "table" then return 0 end

        -- Ищем «свою» профессию: имя → def → def.terrain == terrainId.
        -- Уровень (значение) — 1..100, переводим в 0..1.
        for name, lvl in pairs(opts.known_skills) do
            local def = ProfApi:GetByName(name)
            if def and def.terrain == terrainId then
                local pct = (tonumber(lvl) or 0) / 100
                if pct < 0 then pct = 0 elseif pct > 1 then pct = 1 end
                return pct
            end
        end

        return 0
    end

    -- ========================================================================
    -- str_pct: 0..1.
    --   0 — силы нет или max_strength не задан.
    -- ========================================================================
    function Resolve:StrPct(entity)
        if not entity or not entity.opts then return 0 end
        local opts = entity.opts

        local str = tonumber(opts.strength) or 0
        local max = tonumber(opts.max_strength) or 0
        if max <= 0 then return 0 end

        local pct = str / max
        if pct < 0 then pct = 0 elseif pct > 1 then pct = 1 end
        return pct
    end

    -- ========================================================================
    -- agi_pct: 0..1.
    --   0 — ловкости нет или max_agility не задан.
    -- ========================================================================
    function Resolve:AgiPct(entity)
        if not entity or not entity.opts then return 0 end
        local opts = entity.opts

        local agi = tonumber(opts.agility) or 0
        local max = tonumber(opts.max_agility) or 0
        if max <= 0 then return 0 end

        local pct = agi / max
        if pct < 0 then pct = 0 elseif pct > 1 then pct = 1 end
        return pct
    end

    -- ========================================================================
    -- int_pct: 0..1.
    --   0 — интеллекта нет или max_intellect не задан.
    -- ========================================================================
    function Resolve:IntPct(entity)
        if not entity or not entity.opts then return 0 end
        local opts = entity.opts

        local int = tonumber(opts.intellect) or 0
        local max = tonumber(opts.max_intellect) or 0
        if max <= 0 then return 0 end

        local pct = int / max
        if pct < 0 then pct = 0 elseif pct > 1 then pct = 1 end
        return pct
    end

    -- ========================================================================
    -- stat_pct: 0..1 по имени стата.
    --   "strength" | "agility" | "intellect".
    --   Если stat не задан или неизвестен — 0.
    -- ========================================================================
    function Resolve:StatPct(entity, stat)
        if stat == "strength" then
            return self:StrPct(entity)
        elseif stat == "agility" then
            return self:AgiPct(entity)
        elseif stat == "intellect" then
            return self:IntPct(entity)
        end
        return 0
    end

    -- ========================================================================
    -- Удобный фасад: prof_pct + stat_pct по profDef.stat.
    --   → prof_pct, stat_pct
    -- ========================================================================
    function Resolve:Both(entity, terrainId, stat)
        return self:ProfPct(entity, terrainId), self:StatPct(entity, stat)
    end

    -- ========================================================================
    -- CanSwim: умеет ли существо плавать.
    --   true, если в known_skills есть любая профессия с terrain == "water"
    --   (сейчас — "Пловец", зарегистрирован в df/Professions/Swimmer.lua).
    --
    --   Используется:
    --     AI/Path.lua  → Path:Find(..., entity) — не пускать в воду
    --     AI/Move.lua  → CanStepInto(nextIndex, entity) — не шагать в воду
    --
    --   Если profession "Пловец" в known_skills нет — false.
    --   Если ProfessionsApi не загружен — false (безопасный дефолт).
    -- ========================================================================
    function Resolve:CanSwim(entity)
        if not entity or not entity.opts then return false end

        local opts = entity.opts
        local ProfApi = NSQC4.QuestsDfProfessionsApi
        if not ProfApi or type(opts.known_skills) ~= "table" then return false end

        for name in pairs(opts.known_skills) do
            local def = ProfApi:GetByName(name)
            if def and def.terrain == "water" then
                return true
            end
        end
        return false
    end

end)