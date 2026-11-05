-- ============================================================================
-- NSQC4 / Quests / df / AI / Complete
-- Завершение работы на клетке.
--   - Вызывает Transform:Apply(target, terrainId):
--       * раздаёт лут (в эту клетку или соседние — по правилам Transform/Data)
--       * меняет terrain (tree/stone/grass → earth; earth/pool/ladder → void)
--       * выталкивает существо, если клетка стала void
--   - Профессия: по terrain (earth→digger, tree→lumberjack,
--     stone→stonecutter, grass→herbalist).
--       * одна линия (kinship == бог)        → int * 3
--       * совместное (бог есть + ещё кто-то) → int * 2
--       * бога нет                            → int
--     Потолок шанса — 100%.
--
-- Отладка:
--   /ns_complete on | off | dump | reset
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Complete = {}
    NSQC4.QuestsDfAIComplete = Complete

    local Grid      = NSQC4.QuestsDfGrid
    local Transform = NSQC4.QuestsDfTransform
    local State     = NSQC4.QuestsDfAIState
    local ProfApi   = NSQC4.QuestsDfProfessionsApi

    local PROF_MAX   = 100
    local CHANCE_MAX = 100

    local TERRAIN_TO_PROF = {
        earth = "digger",
        tree  = "lumberjack",
        stone = "stonecutter",
        grass = "herbalist",
    }

    -- Бог профессии (бит): 1 — земля, 2 — поверхность, 4 — ремесло
    local PROF_GOD = {
        digger      = 1,
        lumberjack  = 2,
        herbalist   = 2,
        stonecutter = 1,
    }

    -- ========================================================================
    -- Отладка
    -- ========================================================================
    Complete.DEBUG = true

    local dbg = {
        calls    = 0,
        skipped  = 0,
        maxed    = 0,
        learned  = 0,
        rolls    = 0,
        success  = 0,
        startedAt = GetTime(),
    }
    Complete._dbg = dbg

    local function PrintStats(tag)
        local elapsed = GetTime() - dbg.startedAt
        local rate = (dbg.rolls > 0) and (dbg.success / dbg.rolls * 100) or 0
        print(string.format(
            "[COMPLETE %s] t=%ds calls=%d skip=%d max=%d learn=%d rolls=%d succ=%d rate=%.1f%%",
            tag or "", math.floor(elapsed),
            dbg.calls, dbg.skipped, dbg.maxed, dbg.learned,
            dbg.rolls, dbg.success, rate))
    end

    function Complete:ResetStats()
        dbg.calls    = 0
        dbg.skipped  = 0
        dbg.maxed    = 0
        dbg.learned  = 0
        dbg.rolls    = 0
        dbg.success  = 0
        dbg.startedAt = GetTime()
        print("[COMPLETE] статистика сброшена.")
    end

    function Complete:DumpStats()
        PrintStats("dump")
    end

    -- ========================================================================
    -- Шанс с учётом родства
    -- ========================================================================
    local function CalcChance(int, kinship, godBit)
        int     = tonumber(int) or 0
        kinship = tonumber(kinship) or 0
        godBit  = tonumber(godBit) or 0
        if int <= 0 or godBit <= 0 then
            return 0, 1, "none"
        end

        local hasGod = (math.floor(kinship / godBit) % 2 == 1)
        if not hasGod then
            local p = math.min(CHANCE_MAX, int * 1)
            return p, 1, "none"
        end

        if kinship == godBit then
            local p = math.min(CHANCE_MAX, int * 3)
            return p, 3, "single"
        end

        local p = math.min(CHANCE_MAX, int * 2)
        return p, 2, "mixed"
    end

    local function LineStr(mult, line)
        if line == "single" then return "x3 single"
        elseif line == "mixed" then return "x2 mixed"
        else return "x1 none" end
    end

    -- ========================================================================
    -- Повысить/выучить профессию по terrain.
    -- ========================================================================
    local function TryUpProfession(entity, terrainId)
        dbg.calls = dbg.calls + 1

        if not entity or not entity.opts then
            dbg.skipped = dbg.skipped + 1
            return nil, nil, nil, "skip"
        end
        local opts = entity.opts

        local int = tonumber(opts.intellect) or 0
        if int <= 0 then
            dbg.skipped = dbg.skipped + 1
            return nil, nil, nil, "skip"
        end

        local profId = terrainId and TERRAIN_TO_PROF[terrainId] or nil
        if not profId then
            dbg.skipped = dbg.skipped + 1
            return nil, nil, nil, "noprof"
        end
        local profDef = ProfApi and ProfApi:Get(profId) or nil
        if not profDef or not profDef.name then
            dbg.skipped = dbg.skipped + 1
            return nil, nil, nil, "noprof"
        end

        local skills = opts.known_skills
        if type(skills) ~= "table" then
            skills = {}
            opts.known_skills = skills
        end

        local name   = profDef.name
        local cur    = tonumber(skills[name]) or 0
        local kinship = tonumber(opts.kinship) or 0
        local godBit  = PROF_GOD[profId] or 0
        local chancePct, mult, line = CalcChance(int, kinship, godBit)

        if cur > 0 then
            if cur >= PROF_MAX then
                dbg.maxed = dbg.maxed + 1
                return name, cur, cur, "max", nil, int, chancePct, mult, line
            end

            local roll = math.random(1, 100)
            dbg.rolls = dbg.rolls + 1
            if roll <= chancePct then
                skills[name] = cur + 1
                dbg.success = dbg.success + 1
                return name, cur, cur + 1, "up", roll, int, chancePct, mult, line
            end
            return name, cur, cur, "miss", roll, int, chancePct, mult, line
        end

        local smax    = tonumber(opts.skills_max)     or 0
        local smaxmax = tonumber(opts.max_skills_max) or smax

        if smax >= smaxmax then
            dbg.maxed = dbg.maxed + 1
            return name, 0, 0, "noslot", nil, int, chancePct, mult, line,
                string.format("skills_max=%d/%d", smax, smaxmax)
        end

        local roll = math.random(1, 100)
        dbg.rolls = dbg.rolls + 1
        if roll <= chancePct then
            skills[name] = 1
            opts.skills_max = smax + 1
            dbg.learned = dbg.learned + 1
            dbg.success = dbg.success + 1
            return name, 0, 1, "learn", roll, int, chancePct, mult, line,
                string.format("skills_max %d→%d", smax, smax + 1)
        end
        return name, 0, 0, "learnmiss", roll, int, chancePct, mult, line
    end

    -- ========================================================================
    -- Finish
    -- ========================================================================
    function Complete:Finish(entity)
        if not entity or not entity.opts then return false end

        local ai = entity.opts.ai
        if not ai or not ai.target then return false end

        local target    = ai.target
        local terrainId = ai.terrainId
        local profId    = ai.profId

        local profDef = profId and ProfApi and ProfApi:Get(profId) or nil
        local yield   = profDef and profDef.work and profDef.work.yields or nil

        -- 1. Профессия
        local pname, pold, pnew, result, proll, pint, ppct, pmult, pline, extra =
            TryUpProfession(entity, terrainId)

        local profStr = ""
        if pname then
            local ch = string.format("p=%d%% %s", ppct or 0, LineStr(pmult, pline))
            if result == "up" then
                profStr = string.format(
                    " | ПРОФА %s %d→%d (%s roll=%d/100 int=%d) UP",
                    pname, pold, pnew, ch, proll, pint)
            elseif result == "learn" then
                profStr = string.format(
                    " | ПРОФА %s ВЫУЧЕНА 0→1 (%s roll=%d/100 int=%d) [%s] LEARN",
                    pname, ch, proll, pint, extra or "")
            elseif result == "miss" then
                profStr = string.format(
                    " | ПРОФА %s miss (%s roll=%d/100 int=%d)",
                    pname, ch, proll, pint)
            elseif result == "learnmiss" then
                profStr = string.format(
                    " | ПРОФА %s не выучена (%s roll=%d/100 int=%d)",
                    pname, ch, proll, pint)
            elseif result == "noslot" then
                profStr = string.format(
                    " | ПРОФА %s нет слота (%s) [%s]",
                    pname, ch, extra or "skills_max=max")
            elseif result == "max" then
                profStr = string.format(
                    " | ПРОФА %s=max(100) (шанс был %d%% %s)",
                    pname, ppct or 0, LineStr(pmult, pline))
            end
        elseif result == "noprof" then
            profStr = string.format(" | ПРОФА нет для terrain=%s", tostring(terrainId))
        else
            profStr = " | ПРОФА skip"
        end

        print(string.format("[NSQC4] %s закончил с %s (клетка %d)%s%s",
            entity.opts.name or "Существо",
            terrainId or "?",
            target,
            yield and (" → " .. yield) or "",
            profStr))

        if Complete.DEBUG then
            PrintStats("now")
        end

        -- 2. Преобразование клетки (лут, смена terrain, выталкивание)
        if Transform and Transform.Apply then
            Transform:Apply(target, terrainId)
        elseif Grid then
            Grid:SetHardness(target, 0)
        end

        -- 3. Сброс в idle
        if State and State.SetIdle then
            State:SetIdle(entity)
        end

        return true
    end

    -- ========================================================================
    -- Слэш-команда
    -- ========================================================================
    SLASH_NSCOMPLETE1 = "/ns_complete"
    SlashCmdList["NSCOMPLETE"] = function(msg)
        local cmd = (msg or ""):lower():match("^(%S*)")
        if cmd == "" or cmd == "dump" then
            Complete:DumpStats()
        elseif cmd == "on" then
            Complete.DEBUG = true
            print("[COMPLETE] DEBUG = true")
        elseif cmd == "off" then
            Complete.DEBUG = false
            print("[COMPLETE] DEBUG = false")
        elseif cmd == "reset" then
            Complete:ResetStats()
        else
            print("[COMPLETE] /ns_complete on | off | dump | reset")
        end
    end

end)