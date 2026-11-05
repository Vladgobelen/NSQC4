-- ============================================================================
-- NSQC4 / Quests / df / AI / Stats
-- Прокачка характеристик существ + отладка.
--
-- TryUpVitality — живучесть, шанс int/10000, джекпот (roll == 1) на max_*.
-- TryUpStat(entity, statName) — сила/ловкость/интеллект, шанс int/10000,
--   без джекпота (джекпот уже даёт TryUpVitality на случайный max_*).
--
-- Отладка:
--   /ns_stats on | off | dump | min | reset
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Stats = {}
    NSQC4.QuestsDfAIStats = Stats

    Stats.DEBUG = false

    local MAX_CAP = 100

    local CAP_KEYS = {
        { key = "max_skills_max",  label = "skills_max"  },
        { key = "max_strength",    label = "strength"    },
        { key = "max_agility",     label = "agility"     },
        { key = "max_vitality",    label = "vitality"    },
        { key = "max_intellect",   label = "intellect"   },
    }

    -- Какой стат к какому max_*
    local STAT_MAX = {
        strength  = "max_strength",
        agility   = "max_agility",
        intellect = "max_intellect",
        vitality  = "max_vitality",
    }

    local STAT_LABEL = {
        strength  = "Сила",
        agility   = "Ловкость",
        intellect = "Интеллект",
        vitality  = "Живучесть",
    }

    local dbg = {
        calls        = 0,
        earlyExitInt = 0,
        rolls        = 0,
        successes    = 0,
        jacks        = 0,
        capsRaised   = 0,
        statRolls    = 0,
        statSuccess  = 0,
        sumChance    = 0,
        minRoll      = nil,
        minRollName  = nil,
        minRollInt   = nil,
        startedAt    = GetTime(),
    }
    Stats._dbg = dbg

    local function UpdateEntityMin(opts, roll, int)
        local now = GetTime()
        local em = opts._minRoll
        if not em then
            opts._minRoll = { roll = roll, int = int, firstAt = now, at = now }
            return true
        end
        if not em.firstAt then em.firstAt = now end
        if not em.at then em.at = now end
        if roll < em.roll then
            em.roll = roll
            em.int  = int
            em.at   = now
            return true
        end
        return false
    end

    local function GetEntityMin(opts)
        return opts and opts._minRoll or nil
    end

    local function EntityElapsed(opts)
        local em = opts and opts._minRoll
        if not em or not em.firstAt then return 0 end
        return math.floor(GetTime() - em.firstAt)
    end

    local function RaiseRandomCap(opts)
        local pool = {}
        for _, row in ipairs(CAP_KEYS) do
            local v = tonumber(opts[row.key]) or 0
            if v < MAX_CAP then
                pool[#pool + 1] = row
            end
        end
        if #pool == 0 then return nil end

        local pick = pool[math.random(#pool)]
        local old = tonumber(opts[pick.key]) or 0
        opts[pick.key] = old + 1
        return pick.label, old, opts[pick.key]
    end

    local function RefreshGlobalMin()
        local Grid = NSQC4.QuestsDfGrid
        if not Grid then return end
        local CONST = NSQC4.QuestsFieldConst
        local TOTAL = CONST and (CONST.COLS * CONST.ROWS) or 100

        for i = 1, TOTAL do
            local e = Grid:GetEntity(i)
            if e and e.opts and e.opts._minRoll then
                local em = e.opts._minRoll
                if dbg.minRoll == nil or em.roll < dbg.minRoll then
                    dbg.minRoll     = em.roll
                    dbg.minRollName = tostring(e.opts.name or e.id)
                    dbg.minRollInt  = em.int
                end
            end
        end
    end
    Stats._RefreshGlobalMin = RefreshGlobalMin

    local function PrintSummary(tag)
        local elapsed = GetTime() - dbg.startedAt
        local avgChance = (dbg.rolls > 0) and (dbg.sumChance / dbg.rolls) or 0
        local expected  = avgChance * dbg.rolls
        local minStr = dbg.minRoll
            and string.format("%d(%s,int=%d)", dbg.minRoll,
                tostring(dbg.minRollName), dbg.minRollInt)
            or "nil"

        print(string.format(
            "[STATS %s] t=%ds calls=%d rolls=%d succ=%d caps=%d jack=%d statRolls=%d statSucc=%d chance=%.4f%% exp=%.3f min=%s earlyInt=%d",
            tag or "", math.floor(elapsed),
            dbg.calls, dbg.rolls, dbg.successes, dbg.capsRaised, dbg.jacks,
            dbg.statRolls, dbg.statSuccess,
            avgChance * 100, expected, minStr,
            dbg.earlyExitInt))
    end

    local function PrintPerEntity()
        local Grid = NSQC4.QuestsDfGrid
        if not Grid then return end
        local CONST = NSQC4.QuestsFieldConst
        local TOTAL = CONST and (CONST.COLS * CONST.ROWS) or 100

        local parts = {}
        local list = {}
        for i = 1, TOTAL do
            local e = Grid:GetEntity(i)
            if e and e.opts and e.opts._minRoll then
                list[#list + 1] = {
                    name = tostring(e.opts.name or e.id),
                    min  = e.opts._minRoll.roll,
                    sec  = EntityElapsed(e.opts),
                }
            end
        end
        table.sort(list, function(a, b) return a.min < b.min end)
        for _, r in ipairs(list) do
            parts[#parts + 1] = string.format("%s за %dс min=%d", r.name, r.sec, r.min)
        end

        if #parts == 0 then
            print("[STATS] сущ: —")
        else
            print("[STATS] сущ: " .. table.concat(parts, " | "))
        end
    end

    function Stats:ResetStats()
        dbg.calls        = 0
        dbg.earlyExitInt = 0
        dbg.rolls        = 0
        dbg.successes    = 0
        dbg.jacks        = 0
        dbg.capsRaised   = 0
        dbg.statRolls    = 0
        dbg.statSuccess  = 0
        dbg.sumChance    = 0
        dbg.minRoll      = nil
        dbg.minRollName  = nil
        dbg.minRollInt   = nil
        dbg.startedAt    = GetTime()

        local Grid = NSQC4.QuestsDfGrid
        local CONST = NSQC4.QuestsFieldConst
        local TOTAL = CONST and (CONST.COLS * CONST.ROWS) or 100
        if Grid then
            for i = 1, TOTAL do
                local e = Grid:GetEntity(i)
                if e and e.opts then e.opts._minRoll = nil end
            end
        end

        print("[STATS] счётчики и минимумы сброшены.")
    end

    function Stats:DumpStats()
        RefreshGlobalMin()
        PrintSummary("dump")
        PrintPerEntity()
    end

    function Stats:DumpMin()
        RefreshGlobalMin()
        PrintSummary("min")
        PrintPerEntity()
    end

    -- ========================================================================
    -- Живучесть (с джекпотом на max_*)
    -- ========================================================================
    function Stats:TryUpVitality(entity)
        dbg.calls = dbg.calls + 1

        if not entity or not entity.opts then
            if Stats.DEBUG then print("[STATS] skip: no entity/opts") end
            return false
        end

        local opts = entity.opts
        local name = tostring(opts.name or entity.id)

        local int = tonumber(opts.intellect) or 0
        if int <= 0 then
            dbg.earlyExitInt = dbg.earlyExitInt + 1
            if Stats.DEBUG then
                print(string.format("[STATS] %s skip int=0", name))
            end
            return false
        end

        local chance = int / 10000
        if chance > 1 then chance = 1 end
        dbg.sumChance = dbg.sumChance + chance
        dbg.rolls     = dbg.rolls + 1

        local roll = math.random(1, 10000)
        local hit  = (roll <= int)

        local newEntityMin = UpdateEntityMin(opts, roll, int)

        local newGlobalMin = false
        if dbg.minRoll == nil or roll < dbg.minRoll then
            dbg.minRoll     = roll
            dbg.minRollName = name
            dbg.minRollInt  = int
            newGlobalMin    = true
        end

        local capLabel, capOld, capNew
        if roll == 1 then
            dbg.jacks = dbg.jacks + 1
            capLabel, capOld, capNew = RaiseRandomCap(opts)
            if capLabel then
                dbg.capsRaised = dbg.capsRaised + 1
            end
        end

        local vit    = tonumber(opts.vitality)     or 0
        local maxVit = tonumber(opts.max_vitality) or 0
        local vitUp  = false
        if hit and maxVit > 0 and vit < maxVit then
            opts.vitality = vit + 1
            dbg.successes = dbg.successes + 1
            vitUp = true
        end

        if Stats.DEBUG then
            local em = GetEntityMin(opts)
            local marks = ""
            if newGlobalMin then marks = marks .. " *G" end
            if newEntityMin then marks = marks .. " *E" end
            if roll == 1 then marks = marks .. " *JACK" end

            local capStr = ""
            if capLabel then
                capStr = string.format(" CAP+1 %s %d→%d", capLabel, capOld, capNew)
            elseif roll == 1 then
                capStr = " CAP+1 none (все 100)"
            end

            print(string.format(
                "[STATS] %s за %dс int=%d p=%.4f%% roll=%d/%d %s vit=%d/%d r=%d s=%d caps=%d min=%s/%s%s%s",
                name, EntityElapsed(opts),
                int, chance * 100, roll, 10000,
                hit and (vitUp and "HIT" or "HIT(novit)") or "miss",
                opts.vitality, maxVit,
                dbg.rolls, dbg.successes, dbg.capsRaised,
                em and tostring(em.roll) or "-",
                dbg.minRoll and tostring(dbg.minRoll) or "-",
                capStr, marks))
        end

        return vitUp or (capLabel ~= nil)
    end

    -- ========================================================================
    -- Профильный стат (сила / ловкость / интеллект) — без джекпота.
    -- Шанс int/10000. +1 к текущему, если < max_<stat>.
    -- ========================================================================
    function Stats:TryUpStat(entity, statName)
        if not entity or not entity.opts then return false end
        if not statName then return false end

        local opts = entity.opts
        local name = tostring(opts.name or entity.id)

        local maxKey = STAT_MAX[statName]
        if not maxKey then return false end

        local int = tonumber(opts.intellect) or 0
        if int <= 0 then return false end

        local cur = tonumber(opts[statName]) or 0
        local max = tonumber(opts[maxKey]) or 0
        if max <= 0 or cur >= max then return false end

        dbg.statRolls = dbg.statRolls + 1

        local roll = math.random(1, 10000)
        local hit  = (roll <= int)
        if not hit then return false end

        opts[statName] = cur + 1
        dbg.statSuccess = dbg.statSuccess + 1

        if Stats.DEBUG then
            print(string.format(
                "[STATS] %s %s +1: %d→%d (roll=%d/%d int=%d)",
                name, STAT_LABEL[statName] or statName,
                cur, opts[statName], roll, 10000, int))
        end
        return true
    end

    -- ========================================================================
    -- Слэш-команда
    -- ========================================================================
    SLASH_NSSTATS1 = "/ns_stats"
    SlashCmdList["NSSTATS"] = function(msg)
        local cmd = (msg or ""):lower():match("^(%S*)")
        if cmd == "" or cmd == "dump" then
            Stats:DumpStats()
        elseif cmd == "min" then
            Stats:DumpMin()
        elseif cmd == "on" then
            Stats.DEBUG = true
            print("[STATS] DEBUG = true")
        elseif cmd == "off" then
            Stats.DEBUG = false
            print("[STATS] DEBUG = false")
        elseif cmd == "reset" then
            Stats:ResetStats()
        else
            print("[STATS] /ns_stats on | off | dump | min | reset")
        end
    end

end)