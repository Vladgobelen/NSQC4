-- ============================================================================
-- NSQC4 / Quests / df / Grid / Neighbors
-- Соседи клетки на сетке 10×10 (4-связность).
-- Только индексы. Ничего не знает про проходимость, существ, ландшафт.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Grid = NSQC4.QuestsDfGrid
    if not Grid then
        print("|cffff0000[NSQC4]|r Grid/Neighbors: Grid не загружен.")
        return
    end

    local CONST = NSQC4.QuestsFieldConst
    if not CONST then return end
    local COLS, ROWS = CONST.COLS, CONST.ROWS
    local TOTAL = COLS * ROWS

    -- ========================================================================
    -- Индекс → col, row (0..COLS-1, 0..ROWS-1).
    -- ========================================================================
    local function IndexToColRow(index)
        local i = index - 1
        return i % COLS, math.floor(i / COLS)
    end

    -- ========================================================================
    -- col, row → индекс (1..TOTAL).
    -- ========================================================================
    local function ColRowToIndex(col, row)
        return row * COLS + col + 1
    end

    -- ========================================================================
    -- Соседи клетки (4-связность). Возвращает массив индексов.
    -- ========================================================================
    function Grid:Neighbors(index)
        index = tonumber(index) or 0
        if index < 1 or index > TOTAL then return {} end

        local col, row = IndexToColRow(index)
        local result = {}

        -- Верх
        if row > 0 then
            result[#result + 1] = ColRowToIndex(col, row - 1)
        end
        -- Низ
        if row < ROWS - 1 then
            result[#result + 1] = ColRowToIndex(col, row + 1)
        end
        -- Лево
        if col > 0 then
            result[#result + 1] = ColRowToIndex(col - 1, row)
        end
        -- Право
        if col < COLS - 1 then
            result[#result + 1] = ColRowToIndex(col + 1, row)
        end

        return result
    end

end)