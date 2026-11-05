-- ============================================================================
-- NSQC4 / Quests / df / Goblin / Tooltip
-- Тултип гоблина: регистрация билдера в реестре Entities.
--
-- Регистрируется один раз при загрузке файла:
--   Entities:RegisterTooltip("goblin", buildFn)
--
-- buildFn(opts) → function(btn) — вызывается при каждом рендере клетки
-- с гоблином (TerrainUIApi:RenderCellFromStorage → ResolveTooltip →
-- QuestsField:SetCellTooltip). Сам код тултипа — здесь.
--
-- Общий сборщик AddLine'ов — NSQC4.QuestsDfEntitiesTooltip.Build(opts)
-- (df/Entities/Tooltip.lua). Здесь только привязка kind → Build.
-- Если у гоблина появится уникальная строка тултипа — её место здесь,
-- до или после Build, через отдельный AddLine.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Entities = NSQC4.QuestsDfEntities
    if not Entities then
        print("|cffff0000[NSQC4]|r Goblin/Tooltip: Entities не загружен.")
        return
    end

    if not Entities.RegisterTooltip then
        print("|cffff0000[NSQC4]|r Goblin/Tooltip: Entities:RegisterTooltip не найден (Шаг 4a не применён).")
        return
    end

    -- ========================================================================
    -- Код тултипа гоблина.
    --   opts — данные существа (name/title/description/статы/known_skills)
    --   → возвращает function(btn), которая пишет AddLine'ы.
    --
    -- Сейчас — общий Build. При желании можно добавить гоблин-специфичные
    -- строки до/после, например:
    --   GameTooltip:AddLine("Жадность: " .. (opts.greed or "умеренная"), 0.6, 1, 0.2)
    -- ========================================================================
    local function BuildGoblinTooltip(opts)
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
    -- TerrainUIApi:ResolveTooltip найдёт его через Entities:GetTooltip("goblin").
    -- ========================================================================
    Entities:RegisterTooltip("goblin", BuildGoblinTooltip)

    print("|cff00ffff[GOB-DEBUG]|r Goblin Tooltip зарегистрирован.")
end)