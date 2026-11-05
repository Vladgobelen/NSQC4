-- ============================================================================
-- NSQC4 / Quests / df / Terrain / Logic / Water
-- Логика и генерация типа "Вода" (water).
--
-- Два вида генерации (каждый с шансом 50%):
--   1. Река — две клетки на РАЗНЫХ сторонах поля (10×10), НЕ в углах.
--      Между ними изгибающийся путь из клеток воды (4-связность).
--   2. Озеро — 1..5 клеток воды связным «пятном», НЕ на крайних клетках
--      (col 1..8, row 1..8).
--
-- Каждая клетка воды получает глубину 1..10 (Grid:SetDepth).
--
-- Поведение при кликах — в Actions/Terrain/Water/*. Здесь только:
--   - регистрация типа "water" (onClick/contextMenu = пусто)
--   - SeedRiver()  — река (50% шанс)
--   - SeedLake()   — озеро (50% шанс)
--
-- Глубина зажимается Grid:SetDepth в 1..10 (см. Grid/Depth.lua).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Terrain = NSQC4.QuestsDfTerrain
    if not Terrain then
        print("|cffff0000[NSQC4]|r Terrain/Logic/Water: Terrain не загружен.")
        return
    end

    local Grid = NSQC4.QuestsDfGrid
    if not Grid then
        print("|cffff0000[NSQC4]|r Terrain/Logic/Water: Grid не загружен.")
        return
    end

    local CONST = NSQC4.QuestsFieldConst
    if not CONST then return end
    local COLS, ROWS = CONST.COLS, CONST.ROWS
    local TOTAL = COLS * ROWS

    -- Шанс появления каждого типа (0..1)
    local RIVER_CHANCE = 0.5
    local LAKE_CHANCE  = 0.5

    -- ========================================================================
    -- РЕГИСТРАЦИЯ ТИПА
    -- ========================================================================
    Terrain:RegisterType("water", {
        onClick = function(index)
            -- клики — в Actions/Terrain/Water/*
        end,
        contextMenu = nil,   -- ПКМ пока пустой
    })

    -- ========================================================================
    -- ВСПОМОГАТЕЛЬНОЕ: индекс ↔ (col, row)
    --   col 0..COLS-1, row 0..ROWS-1
    -- ========================================================================
    local function RC(index)
        local i = index - 1
        return i % COLS, math.floor(i / COLS)
    end

    local function CR(col, row)
        return row * COLS + col + 1
    end

    -- ========================================================================
    -- Угловая ли клетка (col,row)?
    -- ========================================================================
    local function IsCorner(col, row)
        local onColEdge = (col == 0) or (col == COLS - 1)
        local onRowEdge = (row == 0) or (row == ROWS - 1)
        return onColEdge and onRowEdge
    end

    -- ========================================================================
    -- ВСПОМОГАТЕЛЬНОЕ: поставить воду + глубину в клетке
    -- ========================================================================
    local function SetWaterCell(index, depth)
        if index < 1 or index > TOTAL then return false end
        Terrain:SetTerrain(index, "water")
        local d = depth or math.random(1, 10)
        if Grid and Grid.SetDepth then
            Grid:SetDepth(index, d)
        end
        return true
    end

    -- ========================================================================
    -- СЛУЧАЙНАЯ КЛЕТКА НА СТОРОНЕ (не в углу)
    --
    --   top    (row = 0):        col 1..COLS-2
    --   bottom (row = ROWS-1):   col 1..COLS-2
    --   left   (col = 0):        row 1..ROWS-2
    --   right  (col = COLS-1):   row 1..ROWS-2
    -- ========================================================================
    local SIDES = { "top", "bottom", "left", "right" }

    local function RandomCellOnSide(side)
        if side == "top" then
            return CR(math.random(1, COLS - 2), 0)
        elseif side == "bottom" then
            return CR(math.random(1, COLS - 2), ROWS - 1)
        elseif side == "left" then
            return CR(0, math.random(1, ROWS - 2))
        elseif side == "right" then
            return CR(COLS - 1, math.random(1, ROWS - 2))
        end
        return nil
    end

    -- ========================================================================
    -- Две РАЗНЫЕ стороны
    -- ========================================================================
    local function PickTwoDifferentSides()
        local a = SIDES[math.random(#SIDES)]
        local b = a
        while b == a do
            b = SIDES[math.random(#SIDES)]
        end
        return a, b
    end

    -- ========================================================================
    -- Строит путь от (c1,r1) до (c2,r2) изгибом.
    -- Возвращает массив индексов клеток (включая старт и финиш).
    -- (Не меняется — старая логика.)
    -- ========================================================================
    local function BuildWindingPath(c1, r1, c2, r2)
        local path = {}
        local visited = {}
        local curCol, curRow = c1, r1

        local function push(col, row)
            local idx = CR(col, row)
            if not visited[idx] then
                visited[idx] = true
                path[#path + 1] = idx
            end
        end

        push(curCol, curRow)

        local maxSteps = COLS * ROWS * 2
        local steps = 0

        while steps < maxSteps do
            steps = steps + 1
            if curCol == c2 and curRow == r2 then break end

            local candidates = {}

            -- Приоритет — направление к финишу
            if curCol < c2 then candidates[#candidates + 1] = { "right", 3 } end
            if curCol > c2 then candidates[#candidates + 1] = { "left",  3 } end
            if curRow < r2 then candidates[#candidates + 1] = { "down",  3 } end
            if curRow > r2 then candidates[#candidates + 1] = { "up",    3 } end

            -- Перпендикулярные «изгибы» — меньший вес, но ненулевой
            if curCol > 0          then candidates[#candidates + 1] = { "left",  1 } end
            if curCol < COLS - 1   then candidates[#candidates + 1] = { "right", 1 } end
            if curRow > 0          then candidates[#candidates + 1] = { "up",    1 } end
            if curRow < ROWS - 1   then candidates[#candidates + 1] = { "down",  1 } end

            if #candidates == 0 then break end

            -- Взвешенный случайный выбор
            local totalW = 0
            for _, c in ipairs(candidates) do totalW = totalW + c[2] end
            local roll = math.random() * totalW
            local acc, chosen = 0, nil
            for _, c in ipairs(candidates) do
                acc = acc + c[2]
                if roll <= acc then chosen = c[1]; break end
            end

            local nc, nr = curCol, curRow
            if chosen == "left"  then nc = nc - 1 end
            if chosen == "right" then nc = nc + 1 end
            if chosen == "up"    then nr = nr - 1 end
            if chosen == "down"  then nr = nr + 1 end

            if nc < 0 then nc = 0 end
            if nc > COLS - 1 then nc = COLS - 1 end
            if nr < 0 then nr = 0 end
            if nr > ROWS - 1 then nr = ROWS - 1 end

            if nc ~= curCol or nr ~= curRow then
                curCol, curRow = nc, nr
                push(curCol, curRow)
            end
        end

        -- На всякий случай: если не дошли до финиша — дотягиваем прямыми шагами
        if curCol ~= c2 or curRow ~= r2 then
            while curCol ~= c2 do
                curCol = curCol + (c2 > curCol and 1 or -1)
                push(curCol, curRow)
            end
            while curRow ~= r2 do
                curRow = curRow + (r2 > curRow and 1 or -1)
                push(curCol, curRow)
            end
        end

        return path
    end

    -- ========================================================================
    -- РЕКА
    --   - шанс RIVER_CHANCE (50%)
    --   - старт и финиш на РАЗНЫХ сторонах, НЕ в углах
    --   - путь изгибом между ними
    --   - если клетки пути выходят в угол (промежуточные) — это допустимо
    --     (ТЗ: «1 клетка реки не в углу, последняя не в углу» — про старт/финиш)
    -- ========================================================================
    function Terrain:SeedRiver(opts)
        opts = opts or {}

        -- шанс появления
        local chance = opts.chance
        if chance == nil then chance = RIVER_CHANCE end
        if math.random() > chance then
            print(string.format("|cff808080[NSQC4]|r Река: нет (шанс %.0f%%)", chance * 100))
            return 0
        end

        local sideA, sideB = PickTwoDifferentSides()
        local startIdx = RandomCellOnSide(sideA)
        local endIdx   = RandomCellOnSide(sideB)
        if not startIdx or not endIdx or startIdx == endIdx then
            return 0
        end

        -- проверка на всякий случай: старт/финиш не в углу
        local sc1, sr1 = RC(startIdx)
        local sc2, sr2 = RC(endIdx)
        if IsCorner(sc1, sr1) or IsCorner(sc2, sr2) then
            print("|cffffaa00[NSQC4]|r Река: старт/финиш попали в угол — пропуск.")
            return 0
        end

        local path = BuildWindingPath(sc1, sr1, sc2, sr2)

        local depthMin = opts.depthMin or 1
        local depthMax = opts.depthMax or 10
        if depthMin < 1 then depthMin = 1 end
        if depthMax > 10 then depthMax = 10 end
        if depthMax < depthMin then depthMax = depthMin end

        local made = 0
        for _, idx in ipairs(path) do
            local d = math.random(depthMin, depthMax)
            if SetWaterCell(idx, d) then made = made + 1 end
        end

        if Terrain.Render then Terrain:Render() end
        print(string.format("|cff00ff00[NSQC4]|r Река: %s → %s, клеток воды: %d",
            tostring(sideA), tostring(sideB), made))
        return made
    end

    -- ========================================================================
    -- ОЗЕРО
    --   - шанс LAKE_CHANCE (50%)
    --   - 1..5 клеток воды связным «пятном»
    --   - только внутренние клетки: col 1..COLS-2, row 1..ROWS-2
    -- ========================================================================

    -- Внутренняя ли клетка (не крайняя)?
    local function IsInner(col, row)
        if col < 1 or col > COLS - 2 then return false end
        if row < 1 or row > ROWS - 2 then return false end
        return true
    end

    -- Соседи (4-связность) — локально
    local function Neighbors4(index)
        local col, row = RC(index)
        local result = {}
        if row > 0 then result[#result + 1] = CR(col, row - 1) end
        if row < ROWS - 1 then result[#result + 1] = CR(col, row + 1) end
        if col > 0 then result[#result + 1] = CR(col - 1, row) end
        if col < COLS - 1 then result[#result + 1] = CR(col + 1, row) end
        return result
    end

    -- Связное пятно: BFS от center до count клеток, ТОЛЬКО внутренние.
    local function BuildLakeCells(center, count)
        local cells = {}
        local visited = {}
        local queue = { center }
        local head = 1
        visited[center] = true

        while head <= #queue and #cells < count do
            local cur = queue[head]
            head = head + 1
            cells[#cells + 1] = cur

            local neigh = Neighbors4(cur)
            for i = #neigh, 2, -1 do
                local j = math.random(i)
                neigh[i], neigh[j] = neigh[j], neigh[i]
            end

            for _, n in ipairs(neigh) do
                if not visited[n] then
                    local nc, nr = RC(n)
                    if IsInner(nc, nr) and #cells + (#queue - head + 1) < count + 1 then
                        visited[n] = true
                        queue[#queue + 1] = n
                    end
                end
            end
        end

        return cells
    end

    -- Список всех внутренних клеток
    local function CollectInnerCells()
        local list = {}
        for row = 1, ROWS - 2 do
            for col = 1, COLS - 2 do
                list[#list + 1] = CR(col, row)
            end
        end
        return list
    end

    -- Публичный API: озеро.
    function Terrain:SeedLake(opts)
        opts = opts or {}

        -- шанс появления
        local chance = opts.chance
        if chance == nil then chance = LAKE_CHANCE end
        if math.random() > chance then
            print(string.format("|cff808080[NSQC4]|r Озеро: нет (шанс %.0f%%)", chance * 100))
            return 0
        end

        local count = tonumber(opts.count) or math.random(1, 5)
        if count < 1 then count = 1 end
        if count > 5 then count = 5 end

        -- центр — только внутренняя клетка
        local inner = CollectInnerCells()
        if #inner == 0 then return 0 end

        local center = inner[math.random(#inner)]
        local cells = BuildLakeCells(center, count)

        local depthMin = opts.depthMin or 1
        local depthMax = opts.depthMax or 10
        if depthMin < 1 then depthMin = 1 end
        if depthMax > 10 then depthMax = 10 end
        if depthMax < depthMin then depthMax = depthMin end

        local made = 0
        for _, idx in ipairs(cells) do
            local d = math.random(depthMin, depthMax)
            if SetWaterCell(idx, d) then made = made + 1 end
        end

        if Terrain.Render then Terrain:Render() end
        print(string.format("|cff00ff00[NSQC4]|r Озеро: центр %d, клеток воды: %d",
            center, made))
        return made
    end

end)