-- ============================================================================
-- NSQC4 / Quests / df / AI / Path
-- Поиск кратчайшего маршрута по сетке 10×10 (BFS, 4-связность).
--
-- Правила:
--   - старт — текущая клетка существа (entity.index)
--   - цель  — клетка target (index)
--   - проходимость: Grid:IsPassable(index) (нет entity на клетке)
--   - старт считается проходимым, даже если на нём стоит само существо
--   - цель считается проходимой, даже если на ней стоит само существо
--
-- Возвращает:
--   { {index, index, …, target}, ... } — массив индексов от старта до цели,
--   включая старт и цель. Если старт == цель → { index }.
--   nil — если пути нет.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Path = {}
    NSQC4.QuestsDfAIPath = Path

    local Grid = NSQC4.QuestsDfGrid
    if not Grid then
        print("|cffff0000[NSQC4]|r AI/Path: Grid не загружен.")
        return
    end

    local CONST = NSQC4.QuestsFieldConst
    if not CONST then return end
    local TOTAL = CONST.COLS * CONST.ROWS

    -- ========================================================================
    -- Восстановить путь по prev[].
    -- ========================================================================
    local function Reconstruct(prev, startIdx, targetIdx)
        local path = {}
        local cur = targetIdx
        while cur ~= nil do
            path[#path + 1] = cur
            if cur == startIdx then break end
            cur = prev[cur]
        end

        -- Развернуть (сейчас от цели к старту).
        local n = #path
        for i = 1, math.floor(n / 2) do
            path[i], path[n - i + 1] = path[n - i + 1], path[i]
        end
        return path
    end

    -- ========================================================================
    -- BFS: кратчайший путь от startIndex до targetIndex.
    --   selfIndex — индекс клетки, на которой стоит существо
    --               (её считаем проходимой даже если entity есть).
    -- ========================================================================
    function Path:Find(startIndex, targetIndex)
        startIndex  = tonumber(startIndex)  or 0
        targetIndex = tonumber(targetIndex) or 0

        if startIndex < 1 or startIndex > TOTAL then return nil end
        if targetIndex < 1 or targetIndex > TOTAL then return nil end

        if startIndex == targetIndex then
            return { startIndex }
        end

        local prev    = {}
        local visited = {}
        local queue   = { startIndex }
        local head    = 1

        visited[startIndex] = true
        prev[startIndex]    = nil

        while head <= #queue do
            local cur = queue[head]
            head = head + 1

            for _, neighbor in ipairs(Grid:Neighbors(cur)) do
                if not visited[neighbor] then
                    -- Проходимость: цель всегда проходима,
                    -- стартовая клетка уже в visited.
                    local passable = Grid:IsPassable(neighbor)
                    if neighbor == targetIndex then passable = true end

                    if passable then
                        visited[neighbor] = true
                        prev[neighbor]    = cur
                        queue[#queue + 1] = neighbor

                        if neighbor == targetIndex then
                            return Reconstruct(prev, startIndex, targetIndex)
                        end
                    end
                end
            end
        end

        return nil
    end

end)