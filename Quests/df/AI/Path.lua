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
--   - ВОДА: проходима только если entity умеет плавать
--     (Resolve:CanSwim(entity) == true). Иначе passable = false.
--     Проверка делается по клетке-соседу (и по цели тоже).
--
-- entity — необязательный третий параметр. Если передан:
--   - Resolve:CanSwim(entity) решает, пускать ли в воду
--   - если не передан — вода считается непроходимой (безопасный дефолт:
--     старый вызов Path:Find(a, b) из внешнего кода не «протечёт» в воду)
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
    -- Можно ли войти в клетку neighbor для данного entity.
    --   - цель всегда проходима (даже если занята существом — оно уйдёт)
    --   - вода: только если entity умеет плавать
    --   - остальное: Grid:IsPassable
    -- ========================================================================
    local function CanEnter(neighbor, targetIndex, canSwim)
        if neighbor == targetIndex then
            -- цель: проверим только воду (void не может быть целью из Find,
            -- но подстрахуемся)
            local c = Grid:GetCell(neighbor)
            if not c then return false end
            if c.terrain == "void" then return false end
            if c.terrain == "water" and not canSwim then return false end
            return true
        end

        local c = Grid:GetCell(neighbor)
        if not c then return false end
        if c.terrain == "void" then return false end
        if c.terrain == "water" and not canSwim then return false end

        return Grid:IsPassable(neighbor)
    end

    -- ========================================================================
    -- BFS: кратчайший путь от startIndex до targetIndex.
    --   entity — опционально; если передан, учитывается CanSwim(entity).
    -- ========================================================================
    function Path:Find(startIndex, targetIndex, entity)
        startIndex  = tonumber(startIndex)  or 0
        targetIndex = tonumber(targetIndex) or 0

        if startIndex < 1 or startIndex > TOTAL then return nil end
        if targetIndex < 1 or targetIndex > TOTAL then return nil end

        if startIndex == targetIndex then
            return { startIndex }
        end

        -- Умеет ли это существо плавать (если entity не передан — false)
        local canSwim = false
        local Resolve = NSQC4.QuestsDfProfessionsResolve
        if entity and Resolve and Resolve.CanSwim then
            canSwim = Resolve:CanSwim(entity) and true or false
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
                    if CanEnter(neighbor, targetIndex, canSwim) then
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