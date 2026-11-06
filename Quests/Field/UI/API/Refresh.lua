-- ============================================================================
-- NSQC4 / Quests / Field / UI / API / Refresh
-- API поля: «перечитай данные Grid и перерисуй клетку / всё поле».
--
-- Это единственный правильный способ заставить поле перерисоваться после
-- изменения данных (Grid: terrain/hardness/entityName/loot/depth, selections).
-- df НЕ собирает spec и НЕ зовёт RenderCell сам — он меняет Grid и просит
-- поле перечитать.
--
-- API:
--   QuestsField:RefreshCell(index)   — перерисовать одну клетку
--   QuestsField:RefreshAllCells()    — перерисовать всё поле
--
-- Внутри — TerrainUIApi:RenderCellFromStorage, который собирает ПОЛНЫЙ spec
-- (bg/terrain/build/loot/entity/highlight) + тултип + клики. Если TerrainUIApi
-- ещё не загружен (например, во время инициализации) — тихо возвращаем false.
--
-- Отличие от RefreshAllCellSizes: тот пересчитывает РАЗМЕРЫ лута/якоря/temp
-- по btn:GetWidth(), не перечитывая данные Grid. Этот — перечитывает данные
-- и перерисовывает слои.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then
        print("|cffff0000[NSQC4]|r Refresh: ядро поля не загружено.")
        return
    end

    local CONST = NSQC4.QuestsFieldConst
    local TOTAL = CONST and (CONST.COLS * CONST.ROWS) or 100

    local function Valid(index)
        index = tonumber(index) or 0
        return (index >= 1 and index <= TOTAL) and index or nil
    end

    local function TerrainUIApi()
        return NSQC4.QuestsDfTerrainUIApi
    end

    -- ========================================================================
    -- Перерисовать одну клетку: перечитать Grid → собрать полный spec →
    -- RenderCell + тултип + клики.
    -- ========================================================================
    function QuestsField:RefreshCell(index)
        index = Valid(index)
        if not index then return false end

        local api = TerrainUIApi()
        if not api or not api.RenderCellFromStorage then
            return false
        end

        return api:RenderCellFromStorage(index)
    end

    -- ========================================================================
    -- Перерисовать всё поле.
    -- ========================================================================
    function QuestsField:RefreshAllCells()
        local api = TerrainUIApi()
        if not api or not api.RenderCellFromStorage then
            return false
        end

        for i = 1, TOTAL do
            api:RenderCellFromStorage(i)
        end
        return true
    end

    print("|cff00ffff[REFRESH]|r Refresh API загружен (RefreshCell / RefreshAllCells).")

end)