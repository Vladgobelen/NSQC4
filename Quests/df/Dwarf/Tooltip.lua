-- ============================================================================
-- NSQC4 / Quests / df / Dwarf / Tooltip
-- Тултип дворфа: регистрация билдера в реестре Entities.
--
-- Регистрируется один раз при загрузке файла:
--   Entities:RegisterTooltip("dwarf", buildFn)
--
-- buildFn(opts) → function(btn) — вызывается при каждом рендере клетки
-- с дворфом (TerrainUIApi:RenderCellFromStorage → ResolveTooltip → 
-- QuestsField:SetCellTooltip). Сам код тултипа — здесь.
--
-- Общий сборщик AddLine'ов — NSQC4.QuestsDfEntitiesTooltip.Build(opts)
-- (df/Entities/Tooltip.lua). Здесь только привязка kind → Build.
-- Если у дворфа появится уникальная строка тултипа — её место здесь,
-- до или после Build, через отдельный AddLine.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Entities = NSQC4.QuestsDfEntities
    if not Entities then
        print("|cffff0000[NSQC4]|r Dwarf/Tooltip: Entities не загружен.")
        return
    end

    if not Entities.RegisterTooltip then
        print("|cffff0000[NSQC4]|r Dwarf/Tooltip: Entities:RegisterTooltip не найден (Шаг 4a не применён).")
        return
    end

    -- ========================================================================
    -- Код тултипа дворфа.
    --   opts — данные существа (name/title/description/статы/known_skills)
    --   → возвращает function(btn), которая пишет AddLine'ы.
    --
    -- Сейчас — общий Build. При желании можно добавить дворф-специфичные
    -- строки до/после, например:
    --   GameTooltip:AddLine("Борода: " .. (opts.beard or "нет"), 0.8, 0.6, 0.4)
    -- ========================================================================
    local function BuildDwarfTooltip(opts)
        if not opts then return nil end

        local Tooltip = NSQC4.QuestsDfEntitiesTooltip
        if Tooltip and Tooltip.Build then
            return Tooltip.Build(opts)
        end

        -- Резерв: если общий Build недоступен — минимальный тултип
        return function(btn)
            GameTooltip:AddLine(opts.name or "Безымянный", 1, 1, 0)
            if opts.title then
                GameTooltip:AddLine("[" .. opts.title .. "]", 1, 0.82, 0)
            end
            if opts.description and opts.description ~= "Описание отсутствует." then
                GameTooltip:AddLine(opts.description, 1, 1, 1, true)
            end
        end
    end

    -- ========================================================================
    -- Регистрация в реестре Entities (kind → билдер).
    -- Вызывается один раз при загрузке файла.
    -- TerrainUIApi:ResolveTooltip найдёт его через Entities:GetTooltip("dwarf").
    -- ========================================================================
    Entities:RegisterTooltip("dwarf", BuildDwarfTooltip)

    print("|cff00ffff[DWF-DEBUG]|r Dwarf Tooltip зарегистрирован.")
end)