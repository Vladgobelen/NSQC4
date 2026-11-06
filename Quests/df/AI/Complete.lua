-- ============================================================================
-- NSQC4 / Quests / df / AI / Complete
-- Режим (build/demolish) определяется по:
--   wasBuilding = ai.wasBuilding (ставится в Work при DONE)
--   + terrainId = ai.terrainId ("ladder" для стройки/лома)
-- ai.workMode НЕ используется (в Work его больше нет).
--
-- ФИКС (строитель — бонус):
--   Раньше для ladder без «Строителя» печаталось «ПРОФА нет для terrain=ladder»
--   (result == "noprof"), что пугало: казалось, что задача не может быть
--   выполнена. Теперь для ladder — «Строитель не выучен (бонус)».
--   Логика TryUpProfession не менялась: если есть свободный слот
--   (skills_max < max_skills_max) — шанс выучить «Строителя»;
--   если уже выучен — шанс поднять на 1.
--
-- ШАГ 8 (через API поля):
--   После смены terrain (Transform:Apply → SetTerrain) клетка
--   перерисовывается через QuestsField:RefreshCell(target). df больше не
--   зовёт TerrainUIApi:RenderCellFromStorage напрямую.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Complete = {}
    NSQC4.QuestsDfAIComplete = Complete

    local Grid      = NSQC4.QuestsDfGrid
    local Transform = NSQC4.QuestsDfTransform
    local State     = NSQC4.QuestsDfAIState
    local ProfApi   = NSQC4.QuestsDfProfessionsApi

    local QuestsField = NSQC4.QuestsField

    local function RefreshCell(index)
        if QuestsField and QuestsField.RefreshCell then
            return QuestsField:RefreshCell(index)
        end
        return false
    end

    local PROF_MAX   = 100
    local CHANCE_MAX = 100

    local TERRAIN_TO_PROF = {
        earth  = "digger",
        tree   = "lumberjack",
        stone  = "stonecutter",
        grass  = "herbalist",
        ladder = "builder",
    }

    local PROF_GOD = {
        digger      = 1,
        lumberjack  = 2,
        herbalist   = 2,
        stonecutter = 1,
        builder     = 1,
    }

    Complete.DEBUG = true

    local dbg = {
        calls    = 0, skipped  = 0, maxed    = 0, learned  = 0,
        rolls    = 0, success  = 0, up       = 0, learn    = 0,
        miss     = 0, noslot   = 0, max      = 0,
        startedAt = GetTime(),
    }
    Complete._dbg = dbg

    local function PrintStats(tag)
        local elapsed = GetTime() - dbg.startedAt
        local rate = (dbg.rolls > 0) and (dbg.success / dbg.rolls * 100) or 0
        print(string.format(
            "[COMPLETE %s] t=%ds calls=%d skip=%d rolls=%d succ=%d rate=%.1f%% | up=%d learn=%d miss=%d noslot=%d max=%d",
            tag or "", math.floor(elapsed),
            dbg.calls, dbg.skipped, dbg.rolls, dbg.success, rate,
            dbg.up, dbg.learn, dbg.miss, dbg.noslot, dbg.max))
    end

    function Complete:ResetStats()
        dbg.calls=0; dbg.skipped=0; dbg.maxed=0; dbg.learned=0
        dbg.rolls=0; dbg.success=0; dbg.up=0; dbg.learn=0
        dbg.miss=0; dbg.noslot=0; dbg.max=0
        dbg.startedAt = GetTime()
        print("[COMPLETE] статистика сброшена.")
    end

    function Complete:DumpStats() PrintStats("dump") end

    local function CalcChance(int, kinship, godBit)
        int     = tonumber(int) or 0
        kinship = tonumber(kinship) or 0
        godBit  = tonumber(godBit) or 0
        if int <= 0 or godBit <= 0 then return 0, 1, "none" end
        local hasGod = (math.floor(kinship / godBit) % 2 == 1)
        if not hasGod then return math.min(CHANCE_MAX, int * 1), 1, "none" end
        if kinship == godBit then return math.min(CHANCE_MAX, int * 3), 3, "single" end
        return math.min(CHANCE_MAX, int * 2), 2, "mixed"
    end

    local function LineStr(mult, line)
        if line == "single" then return "x3 single"
        elseif line == "mixed" then return "x2 mixed"
        else return "x1 none" end
    end

    local function PrintSkillLine(entity, terrainId, profId)
        if not Complete.DEBUG then return end
        local opts = entity and entity.opts or {}
        local sk = {}
        for n, l in pairs(opts.known_skills or {}) do
            sk[#sk + 1] = tostring(n) .. ":" .. tostring(l)
        end
        table.sort(sk)
        print(string.format(
            "[COMPLETE skill] %s | int=%s kin=%s gods=%s | skills_max=%s/%s known=[%s] | terrain=%s profId=%s",
            tostring(opts.name or (entity and entity.id) or "?"),
            tostring(opts.intellect), tostring(opts.kinship),
            (opts.gods and table.concat(opts.gods, ",")) or "-",
            tostring(opts.skills_max), tostring(opts.max_skills_max),
            table.concat(sk, ", "), tostring(terrainId), tostring(profId)))
    end

    local function TryUpProfession(entity, terrainId)
        dbg.calls = dbg.calls + 1
        if not entity or not entity.opts then dbg.skipped = dbg.skipped + 1; return nil, nil, nil, "skip" end
        local opts = entity.opts
        local int = tonumber(opts.intellect) or 0
        if int <= 0 then dbg.skipped = dbg.skipped + 1; return nil, nil, nil, "skip" end

        local profId = terrainId and TERRAIN_TO_PROF[terrainId] or nil
        if not profId then dbg.skipped = dbg.skipped + 1; return nil, nil, nil, "noprof" end
        local profDef = ProfApi and ProfApi:Get(profId) or nil
        if not profDef or not profDef.name then dbg.skipped = dbg.skipped + 1; return nil, nil, nil, "noprof" end

        local skills = opts.known_skills
        if type(skills) ~= "table" then skills = {}; opts.known_skills = skills end

        local name   = profDef.name
        local cur    = tonumber(skills[name]) or 0
        local kinship = tonumber(opts.kinship) or 0
        local godBit  = PROF_GOD[profId] or 0
        local chancePct, mult, line = CalcChance(int, kinship, godBit)

        if cur > 0 then
            if cur >= PROF_MAX then
                dbg.maxed = dbg.maxed + 1; dbg.max = dbg.max + 1
                return name, cur, cur, "max", nil, int, chancePct, mult, line
            end
            local roll = math.random(1, 100)
            dbg.rolls = dbg.rolls + 1
            if roll <= chancePct then
                skills[name] = cur + 1
                dbg.success = dbg.success + 1; dbg.up = dbg.up + 1
                return name, cur, cur + 1, "up", roll, int, chancePct, mult, line
            end
            dbg.miss = dbg.miss + 1
            return name, cur, cur, "miss", roll, int, chancePct, mult, line
        end

        local smax    = tonumber(opts.skills_max)     or 0
        local smaxmax = tonumber(opts.max_skills_max) or smax
        if smax >= smaxmax then
            dbg.maxed = dbg.maxed + 1; dbg.noslot = dbg.noslot + 1
            return name, 0, 0, "noslot", nil, int, chancePct, mult, line,
                string.format("skills_max=%d/%d", smax, smaxmax)
        end

        local roll = math.random(1, 100)
        dbg.rolls = dbg.rolls + 1
        if roll <= chancePct then
            skills[name] = 1
            opts.skills_max = smax + 1
            dbg.learned = dbg.learned + 1; dbg.learn = dbg.learn + 1
            dbg.success = dbg.success + 1
            return name, 0, 1, "learn", roll, int, chancePct, mult, line,
                string.format("skills_max %d→%d", smax, smax + 1)
        end
        dbg.miss = dbg.miss + 1
        return name, 0, 0, "learnmiss", roll, int, chancePct, mult, line
    end

    -- ========================================================================
    -- Finish
    -- ========================================================================
    function Complete:Finish(entity)
        if not entity or not entity.opts then return false end

        local ai = entity.opts.ai
        if not ai or not ai.target then return false end

        local target     = ai.target
        local workTarget = ai.workTarget or ai.target
        local terrainId  = ai.terrainId
        local profId     = ai.profId or TERRAIN_TO_PROF[terrainId]

        local wasBuilding = (ai.wasBuilding == true)
        ai.wasBuilding = nil

        local profDef = profId and ProfApi and ProfApi:Get(profId) or nil
        local yield   = profDef and profDef.work and profDef.work.yields or nil

        PrintSkillLine(entity, terrainId, profId)

        local pname, pold, pnew, result, proll, pint, ppct, pmult, pline, extra =
            TryUpProfession(entity, terrainId)

        local profStr = ""
        if pname then
            local ch = string.format("p=%d%% %s", ppct or 0, LineStr(pmult, pline))
            if result == "up" then
                profStr = string.format(" | ПРОФА %s %d→%d (%s roll=%d/100 int=%d) UP",
                    pname, pold, pnew, ch, proll, pint)
            elseif result == "learn" then
                profStr = string.format(" | ПРОФА %s ВЫУЧЕНА 0→1 (%s roll=%d/100 int=%d) [%s] LEARN",
                    pname, ch, proll, pint, extra or "")
            elseif result == "miss" then
                profStr = string.format(" | ПРОФА %s miss (%s roll=%d/100 int=%d)",
                    pname, ch, proll, pint)
            elseif result == "learnmiss" then
                profStr = string.format(" | ПРОФА %s не выучена (%s roll=%d/100 int=%d)",
                    pname, ch, proll, pint)
            elseif result == "noslot" then
                profStr = string.format(" | ПРОФА %s нет слота (%s) [%s]",
                    pname, ch, extra or "skills_max=max")
            elseif result == "max" then
                profStr = string.format(" | ПРОФА %s=max(100) (шанс был %d%% %s)",
                    pname, ppct or 0, LineStr(pmult, pline))
            end
        elseif result == "noprof" then
            if terrainId == "ladder" then
                profStr = " | Строитель не выучен (бонус)"
            else
                profStr = string.format(" | ПРОФА нет для terrain=%s", tostring(terrainId))
            end
        else
            profStr = " | ПРОФА skip"
        end

        print(string.format("[NSQC4] %s закончил с %s (клетка %d)%s%s",
            entity.opts.name or "Существо",
            terrainId or "?", workTarget or target,
            yield and (" → " .. yield) or "", profStr))

        if Complete.DEBUG then PrintStats("now") end

        -- ====================================================================
        -- BUILD / DEMOLISH: режим — по wasBuilding + terrainId.
        -- ====================================================================
        if wasBuilding and Grid and Grid.IsBuilding then
            if terrainId == "ladder" then
                local b = Grid:GetBuilding(workTarget)
                local hp  = b and tonumber(b.hp)  or 0
                local max = b and tonumber(b.max) or 0

                if max > 0 and hp >= max then
                    print(string.format(
                        "|cff00ff00[NSQC4]|r Постройка завершена (клетка %d), лестница готова.",
                        workTarget))
                elseif hp <= 0 then
                    print(string.format(
                        "|cffff8800[NSQC4]|r Лестница сломана (клетка %d).", workTarget))
                    local Terrain = NSQC4.QuestsDfTerrain
                    if Terrain and Terrain.SetTerrain then
                        Terrain:SetTerrain(workTarget, "void")
                    end
                    RefreshCell(workTarget)
                else
                    print(string.format(
                        "|cffffaa00[NSQC4]|r Лестница в клетке %d: hp=%d/%d (непонятное состояние).",
                        workTarget, hp, max))
                end
                if State and State.SetIdle then State:SetIdle(entity) end
                return true
            end
        end

        -- ====================================================================
        -- ОБЫЧНАЯ РАБОТА
        -- ====================================================================
        if wasBuilding then
            print(string.format(
                "|cff00ff00[NSQC4]|r Постройка завершена (клетка %d), лестница готова.",
                workTarget))
        else
            local isUnfinishedBuilding = (terrainId == "ladder")
                and Grid and Grid.IsBuilding and Grid:IsBuilding(workTarget)
            if isUnfinishedBuilding then
                print(string.format(
                    "|cffffaa00[NSQC4]|r Постройка приостановлена (клетка %d): не хватает материала.",
                    workTarget))
            else
                if Transform and Transform.Apply then
                    Transform:Apply(target, terrainId)
                elseif Grid then
                    Grid:SetHardness(target, 0)
                end
                -- Transform:Apply меняет terrain через Terrain:SetTerrain,
                -- который сам зовёт RenderCellFromStorage. Но на всякий случай
                -- — RefreshCell, если Apply не сработал (fallback ветка).
                RefreshCell(target)
            end
        end

        if State and State.SetIdle then State:SetIdle(entity) end
        return true
    end

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