-- ============================================================================
-- NSQC4 / Quests / df / Professions / Resolve
-- Перевод данных существа в числа, которые ждёт формула профессии,
-- + проверка «умеет ли существо плавать» (для воды).
--
-- ФОРМУЛА ЛЮБОЙ ПРОФЕССИИ:
--   clicks(hardness, prof_pct, stat_pct)
--
--   prof_pct — уровень профессии / 100 (0..1)
--   stat_pct — стат / 100 (0..1)  ← ВСЕГДА НА 100, не на max_*
--
-- ВАЖНО:
--   max_strength / max_agility / max_intellect — это ОГРАНИЧИТЕЛИ РОСТА
--   (TryUpStat не даст поднять стат выше max_*). В формулу они НЕ идут.
--   Потолок вклада стата — всегда 100, как и у профессии.
--
--   Пример: agility=8, max_agility=9 → sp = 8/100 = 0.08 (а не 8/9=0.889).
--   Пример: agility=8, max_agility=100 → sp = 8/100 = 0.08 (то же самое).
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
    --   Уровень профессии / 100. 0 — нет подходящей профессии для terrain.
    -- ========================================================================
    function Resolve:ProfPct(entity, terrainId)
        if not entity or not entity.opts then return 0 end
        if type(terrainId) ~= "string" or terrainId == "" then return 0 end

        local opts = entity.opts
        local ProfApi = NSQC4.QuestsDfProfessionsApi
        if not ProfApi or type(opts.known_skills) ~= "table" then return 0 end

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
    -- StrPct: 0..1.  ВСЕГДА strength / 100.
    -- ========================================================================
    function Resolve:StrPct(entity)
        if not entity or not entity.opts then return 0 end
        local opts = entity.opts

        local str = tonumber(opts.strength) or 0
        local pct = str / 100
        if pct < 0 then pct = 0 elseif pct > 1 then pct = 1 end
        return pct
    end

    -- ========================================================================
    -- AgiPct: 0..1.  ВСЕГДА agility / 100.
    -- ========================================================================
    function Resolve:AgiPct(entity)
        if not entity or not entity.opts then return 0 end
        local opts = entity.opts

        local agi = tonumber(opts.agility) or 0
        local pct = agi / 100
        if pct < 0 then pct = 0 elseif pct > 1 then pct = 1 end
        return pct
    end

    -- ========================================================================
    -- IntPct: 0..1.  ВСЕГДА intellect / 100.
    -- ========================================================================
    function Resolve:IntPct(entity)
        if not entity or not entity.opts then return 0 end
        local opts = entity.opts

        local int = tonumber(opts.intellect) or 0
        local pct = int / 100
        if pct < 0 then pct = 0 elseif pct > 1 then pct = 1 end
        return pct
    end

    -- ========================================================================
    -- StatPct: 0..1 по имени стата.
    --   "strength" | "agility" | "intellect".
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
    -- Both: prof_pct + stat_pct.
    -- ========================================================================
    function Resolve:Both(entity, terrainId, stat)
        return self:ProfPct(entity, terrainId), self:StatPct(entity, stat)
    end

    -- ========================================================================
    -- CanSwim: умеет ли существо плавать.
    --   true, если в known_skills есть любая профессия с terrain == "water".
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