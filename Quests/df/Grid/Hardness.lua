-- ============================================================================
-- NSQC4 / Quests / df / Grid / Hardness
-- Прочность клетки: текущее HP, которое существо снимает копанием.
--
-- Живёт в cell.hardness (третье поле таблицы клетки, рядом с terrain/entity).
-- Базовая прочность типа ландшафта — в df/Terrain/Data.lua.
-- Этот файл — только про cell.hardness: поставить, получить, сбросить, проверить.
-- Никакой логики копания, таймеров, рендера, кликов.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Grid = NSQC4.QuestsDfGrid
    if not Grid then
        print("|cffff0000[NSQC4]|r Grid/Hardness: Grid не загружен.")
        return
    end

    -- ========================================================================
    -- Поставить текущее HP клетки.
    --   index  — 1..100
    --   value  — число (может быть 0), nil = сбросить
    -- ========================================================================
    function Grid:SetHardness(index, value)
        local c = self:GetCell(index)
        if not c then return false end
        c.hardness = value
        return true
    end

    -- ========================================================================
    -- Получить текущее HP клетки.
    --   nil — если не задано (клетка пустая / только что очищена)
    -- ========================================================================
    function Grid:GetHardness(index)
        local c = self:GetCell(index)
        return c and c.hardness or nil
    end

    -- ========================================================================
    -- Сбросить HP клетки в nil.
    -- ========================================================================
    function Grid:ClearHardness(index)
        local c = self:GetCell(index)
        if not c then return false end
        c.hardness = nil
        return true
    end

    -- ========================================================================
    -- Проверить, истощена ли клетка (HP <= 0).
    --   nil-значение считается «не истощена» (ещё не назначено — не наша зона).
    -- ========================================================================
    function Grid:IsDepleted(index)
        local c = self:GetCell(index)
        if not c then return false end
        if c.hardness == nil then return false end
        return c.hardness <= 0
    end

end)