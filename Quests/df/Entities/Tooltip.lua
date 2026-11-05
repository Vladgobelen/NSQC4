-- ============================================================================
-- NSQC4 / Quests / df / Entities / Tooltip
-- Сборка GameTooltip для существа.
--
-- opts._landscape = { index, terrainId } — используется только чтобы
-- Terrain/UI/Api мог дописать строки клетки (Клетка / Прочность / Лут).
-- Сам Tooltip.Build ландшафт НЕ рисует — это делает Terrain/UI/Api.
--
-- Строки:
--   имя / титул / описание
--   статы
--   ПРОФЕССИИ
--   РОДСТВО
--
-- Отладка:
--   /run NSQC4.QuestsDfTooltip__DEBUG = true
--   /run NSQC4.QuestsDfTooltip__DEBUG_SKILLS = true
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Tooltip = {}
    NSQC4.QuestsDfEntitiesTooltip = Tooltip

    local function dbgSkills(...)
        if NSQC4.QuestsDfTooltip__DEBUG_SKILLS then
            print("|cffffaa00[TT-SKILLS]|r", ...)
        end
    end

    local function GetColorByPercent(val, maxVal)
        if not val or not maxVal or maxVal == 0 then return 0.62, 0.62, 0.62 end
        local percent = val / maxVal
        if percent <= 0.05 then return 0.62, 0.62, 0.62
        elseif percent <= 0.15 then return 1.00, 1.00, 1.00
        elseif percent <= 0.30 then return 0.12, 1.00, 0.00
        elseif percent <= 0.50 then return 0.00, 0.44, 0.87
        elseif percent <= 0.70 then return 0.64, 0.21, 0.93
        elseif percent <= 0.90 then return 1.00, 0.50, 0.00
        else return 0.90, 0.80, 0.50
        end
    end
    Tooltip.GetColorByPercent = GetColorByPercent

    local function BuildSkillsLine(known_skills)
        if type(known_skills) ~= "table" then
            dbgSkills("BuildSkillsLine: known_skills is not table, type=",
                      type(known_skills))
            return nil
        end

        local parts = {}
        local count = 0

        for name, lvl in pairs(known_skills) do
            count = count + 1
            parts[#parts + 1] = tostring(name) .. ": " .. tostring(lvl)
            dbgSkills(string.format("  [%s] = %s (type name=%s, type lvl=%s)",
                tostring(name), tostring(lvl), type(name), type(lvl)))
        end

        if count == 0 then
            dbgSkills("BuildSkillsLine: empty → nil")
            return nil
        end

        table.sort(parts)
        local line = table.concat(parts, ", ")
        dbgSkills("BuildSkillsLine: line = " .. line)
        return line
    end

    -- ========================================================================
    -- Строка родства: "Родство: Железобетонсон, Шельма Задранец"
    -- Если gods пуст — "Родство: Безродный"
    -- ========================================================================
    local function BuildKinshipLine(opts)
        if not opts then return nil end
        local gods = opts.gods
        if type(gods) ~= "table" or #gods == 0 then
            return "Родство: |cff808080Безродный|r", 0.62, 0.62, 0.62
        end
        local names = table.concat(gods, ", ")
        if #gods == 1 then
            return "Родство: " .. names, 1.00, 0.82, 0.00
        elseif #gods == 2 then
            return "Родство: " .. names, 0.30, 0.90, 0.30
        else
            return "Родство: " .. names .. " (все трое)", 0.20, 0.60, 1.00
        end
    end

    function Tooltip.Build(opts)
        if not opts then return nil end

        return function(btn)
            if NSQC4.QuestsDfTooltip__DEBUG then
                print(string.format("[TT] name=%s title=%s kind=%s",
                    tostring(opts.name), tostring(opts.title), tostring(opts.kind)))
                local land = opts._landscape
                if land then
                    print(string.format("[TT] landscape index=%s terrain=%s",
                        tostring(land.index), tostring(land.terrainId)))
                end
                print(string.format("[TT] kinship=%s gods=%s",
                    tostring(opts.kinship),
                    type(opts.gods) == "table" and table.concat(opts.gods, ",") or "nil"))
            end

            -- ИМЯ / ТИТУЛ / ОПИСАНИЕ
            GameTooltip:AddLine(opts.name or "Безымянный", 1, 1, 0)

            if opts.title then
                GameTooltip:AddLine("[" .. opts.title .. "]", 1, 0.82, 0)
            end

            if opts.description and opts.description ~= "Описание отсутствует." then
                GameTooltip:AddLine(opts.description, 1, 1, 1, true)
            end

            GameTooltip:AddLine(" ")

            -- СТАТЫ
            if opts.skills_max and opts.skills_cap then
                local r, g, b = GetColorByPercent(opts.skills_cap, opts.max_skills_cap)
                GameTooltip:AddLine(string.format("Умения: %d / %d",
                    opts.skills_max, opts.max_skills_cap or opts.skills_cap), r, g, b)
            end

            if opts.strength then
                local r, g, b = GetColorByPercent(opts.strength, opts.max_strength)
                GameTooltip:AddLine(string.format("Сила: %d / %d",
                    opts.strength, opts.max_strength or opts.strength), r, g, b)
            end

            if opts.agility then
                local r, g, b = GetColorByPercent(opts.agility, opts.max_agility)
                GameTooltip:AddLine(string.format("Ловкость: %d / %d",
                    opts.agility, opts.max_agility or opts.agility), r, g, b)
            end

            if opts.vitality then
                local r, g, b = GetColorByPercent(opts.vitality, opts.max_vitality)
                GameTooltip:AddLine(string.format("Живучесть: %d / %d",
                    opts.vitality, opts.max_vitality or opts.vitality), r, g, b)
            end

            if opts.intellect then
                local r, g, b = GetColorByPercent(opts.intellect, opts.max_intellect)
                GameTooltip:AddLine(string.format("Интеллект: %d / %d",
                    opts.intellect, opts.max_intellect or opts.intellect), r, g, b)
            end

            if opts.lineage ~= nil then
                local lineageStr = (opts.lineage == 1)
                    and "|cffffd100Аристократ|r"
                    or  "|cff808080Безродный|r"
                GameTooltip:AddLine("Происхождение: " .. lineageStr, 1, 1, 1)
            end

            -- ПРОФЕССИИ
            local skillsLine = BuildSkillsLine(opts.known_skills)
            if skillsLine then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Профессии:", 1, 0.82, 0.0)
                GameTooltip:AddLine(skillsLine, 0.8, 1.0, 0.8, true)
            end

            -- РОДСТВО
            local kline, kr, kg, kb = BuildKinshipLine(opts)
            if kline then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(kline, kr, kg, kb, true)
            end

            -- ЛАНДШАФТ здесь НЕ выводится — это делает Terrain/UI/Api
            -- (Клетка / Прочность / Лут) после tooltipFn(btn).
        end
    end

end)