-- ============================================================================
-- NSQC4 / Quests / df / Grid / Depth
-- Глубина клетки воды: cell.depth (1..10).
--
-- Живёт в cell.depth — рядом с terrain/entityName/hardness/loot.
-- Базовая «глубина по умолчанию» для воды — не здесь, а в генераторе воды
-- (df/Terrain/Logic/Water.lua): он решает, какую глубину ставить каждой
-- клетке реки/озера.
--
-- Этот файл — только про cell.depth: поставить, получить, сбросить, проверить.
-- Никакой логики плавания, кликов, рендера здесь нет.
--
-- API:
--   Grid:SetDepth(index, value)     -- 1..10, nil = сброс
--   Grid:GetDepth(index)            -- 1..10 | nil
--   Grid:ClearDepth(index)          -- сброс в nil
--   Grid:HasDepth(index)            -- true, если depth задан (1..10)
--   Grid:IsWater(index)             -- true, если terrain == "water"
--   Grid:IsDeepWater(index, minD)   -- true, если вода и depth >= minD
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Grid = NSQC4.QuestsDfGrid
    if not Grid then
        print("|cffff0000[NSQC4]|r Grid/Depth: Grid не загружен.")
        return
    end

    local MIN_DEPTH = 1
    local MAX_DEPTH = 10

    -- ========================================================================
    -- Поставить глубину клетки.
    --   index  — 1..100
    --   value  — 1..10, nil = сброс
    --   Значения вне диапазона зажимаются в 1..10.
    -- ========================================================================
    function Grid:SetDepth(index, value)
        local c = self:GetCell(index)
        if not c then return false end

        if value == nil then
            c.depth = nil
            return true
        end

        local v = math.floor((tonumber(value) or MIN_DEPTH) + 0.5)
        if v < MIN_DEPTH then v = MIN_DEPTH end
        if v > MAX_DEPTH then v = MAX_DEPTH end
        c.depth = v
        return true
    end

    -- ========================================================================
    -- Получить глубину клетки.
    --   nil — если не задана (не вода / только что очищена)
    -- ========================================================================
    function Grid:GetDepth(index)
        local c = self:GetCell(index)
        return c and c.depth or nil
    end

    -- ========================================================================
    -- Сбросить глубину в nil.
    -- ========================================================================
    function Grid:ClearDepth(index)
        local c = self:GetCell(index)
        if not c then return false end
        c.depth = nil
        return true
    end

    -- ========================================================================
    -- Есть ли у клетки заданная глубина (1..10).
    -- ========================================================================
    function Grid:HasDepth(index)
        local c = self:GetCell(index)
        if not c then return false end
        local d = c.depth
        return d ~= nil and d >= MIN_DEPTH and d <= MAX_DEPTH
    end

    -- ========================================================================
    -- Вода ли в клетке (terrain == "water").
    -- ========================================================================
    function Grid:IsWater(index)
        local c = self:GetCell(index)
        if not c then return false end
        return c.terrain == "water"
    end

    -- ========================================================================
    -- Глубокая ли вода: вода + depth >= minD (по умолчанию 1).
    --   Если minD <= 1 — эквивалентно IsWater(index).
    -- ========================================================================
    function Grid:IsDeepWater(index, minD)
        minD = tonumber(minD) or MIN_DEPTH
        if not self:IsWater(index) then return false end
        local d = self:GetDepth(index)
        if d == nil then return false end
        return d >= minD
    end

    -- ========================================================================
    -- Экспорт констант (для генератора воды и тултипа).
    -- ========================================================================
    Grid.DEPTH_MIN = MIN_DEPTH
    Grid.DEPTH_MAX = MAX_DEPTH

end)