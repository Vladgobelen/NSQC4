-- ============================================================================
-- NSQC4 / Quests / df / Goblin / Spawner
-- Генерация гоблина. Уникальное имя. known_skills[name] = уровень (1..prof_max).
-- Родство: kinship по буквам имени (Ы/У/О), gods — список богов.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local IMG_PATH = "Interface\\AddOns\\NSQC4\\Media\\Images\\"
    local Goblin = NSQC4.QuestsDfGoblin
    if not Goblin then return end

    local WEIGHTS = {
        [1] = 1, [2] = 9, [3] = 20, [4] = 40, [5] = 80,
        [6] = 100, [7] = 120, [8] = 150, [9] = 180, [10] = 300
    }

    local function GetRandomLength()
        local totalWeight = 0
        for _, w in pairs(WEIGHTS) do totalWeight = totalWeight + w end
        local roll = math.random(totalWeight)
        local current = 0
        for len = 1, 10 do
            current = current + (WEIGHTS[len] or 0)
            if roll <= current then return len end
        end
        return 10
    end

    local function ShuffleArray(array)
        local result = {}
        for i = 1, #array do result[i] = array[i] end
        for i = #result, 2, -1 do
            local j = math.random(i)
            result[i], result[j] = result[j], result[i]
        end
        return result
    end

    local function RollBehavior()
        return (math.random() < 0.5) and "aggressive" or "peaceful"
    end

    local function PickUniqueName(names, category)
        local Entities = NSQC4.QuestsDfEntities
        if not Entities then return nil end
        local byName = Entities:EnsureByName()
        local list = names[category]
        if not list or #list == 0 then return nil end

        for _ = 1, 50 do
            local name = list[math.random(#list)]
            if not byName[name] then return name end
        end
        local base = list[math.random(#list)]
        for i = 2, 999 do
            local name = base .. "#" .. i
            if not byName[name] then return name end
        end
        return nil
    end

    function Goblin:Spawn(index)
        index = tonumber(index) or 0
        if index < 1 or index > 100 then return nil end

        local Entities = NSQC4.QuestsDfEntities
        if not Entities then return nil end

        local names = NSQC4.QuestsDfGoblinNames
        if not names then return nil end

        local category = GetRandomLength()
        local name = PickUniqueName(names, category)
        if not name then
            print("|cffff0000[NSQC4]|r Goblin:Spawn: не удалось подобрать уникальное имя")
            return nil
        end

        -- Родство (kinship + gods)
        local kinship, gods
        local Gods = NSQC4.QuestsDfGoblinGods
        if Gods then
            kinship = Gods:GetKinship(name)
            gods    = Gods:GetGods(kinship)
        end

        local descTable = NSQC4.QuestsDfGoblinDescriptions or {}
        local desc = descTable[category] or descTable[99] or "Описание отсутствует."

        local statsTable = NSQC4.QuestsDfGoblinStats
        local stats = (statsTable and statsTable[category]) or {}

        local function rollStat(range, defaultMin)
            if not range or #range < 2 then return defaultMin, defaultMin end
            return math.random(range[1], range[2]), range[2]
        end

        local skills_max, skills_max_cap = rollStat(stats.skills_max, 1)
        local skills_cap, skills_cap_max = rollStat(stats.skills_cap, 1)
        local strength, strength_max       = rollStat(stats.strength, 1)
        local agility, agility_max         = rollStat(stats.agility, 1)
        local vitality, vitality_max       = rollStat(stats.vitality, 1)
        local intellect, intellect_max     = rollStat(stats.intellect, 1)

        local lineage, lineage_max = 0, 1
        if stats.lineage then lineage, lineage_max = rollStat(stats.lineage, 0) end

        local known_skills = {}
        local allProf = NSQC4.QuestsDfProfessions
        if allProf and #allProf > 0 then
            local shuffled = ShuffleArray(allProf)

            local profMin = (stats.prof and stats.prof[1]) or 1
            local profMax = (stats.prof and stats.prof[2]) or 1
            if profMin > profMax then profMin, profMax = profMax, profMin end

            local need = skills_max
            local added = 0
            local seen = {}

            for i = 1, #shuffled do
                if added >= need then break end
                local def = shuffled[i]
                if def and def.name and not seen[def.name] then
                    seen[def.name] = true
                    known_skills[def.name] = math.random(profMin, profMax)
                    added = added + 1
                end
            end
        end

        local statuses = {
            [1] = "Бог", [2] = "Полубог", [3] = "Царь", [4] = "Герой", [5] = "Воин",
            [6] = "Новобранец", [7] = "Гражданин", [8] = "Мигрант", [9] = "Преступник", [10] = "Отброс"
        }
        local title = statuses[category] or "Неизвестный"

        local opts = {
            name = name, title = title, description = desc,
            texture = IMG_PATH .. "gob", icon = IMG_PATH .. "gob",
            color = { 1.00, 1.00, 0.00 }, kind = "goblin",
            expanded = false,
            alpha = 1.0,
            behavior = RollBehavior(),

            skills_max = skills_max, skills_cap = skills_cap,
            strength = strength, agility = agility, vitality = vitality, intellect = intellect,
            lineage = lineage,

            max_skills_max = skills_max_cap, max_skills_cap = skills_cap_max,
            max_strength = strength_max, max_agility = agility_max,
            max_vitality = vitality_max, max_intellect = intellect_max, max_lineage = lineage_max,

            known_skills = known_skills,

            kinship = kinship,
            gods    = gods,
        }

        local entity = Entities:Spawn(nil, index, opts)
        if entity then
            local skillParts = {}
            for pname, lvl in pairs(known_skills) do
                skillParts[#skillParts + 1] = pname .. ":" .. tostring(lvl)
            end
            table.sort(skillParts)
            local skillsStr = table.concat(skillParts, ", ")
            local godsStr = (gods and #gods > 0) and table.concat(gods, ",") or "-"
            print(string.format("|cff00ff00[NSQC4]|r Спавн гоблина: %s [%s] | %s | УМ: %d | kin=%s(%s) | Профессии: %s",
                name, title, opts.behavior, skills_max, tostring(kinship), godsStr,
                skillsStr ~= "" and skillsStr or "нет"))
        end
        return entity
    end

end)