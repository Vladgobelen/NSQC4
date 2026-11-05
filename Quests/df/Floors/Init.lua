-- ============================================================================
-- NSQC4 / Quests / df / Floors / Init
-- Реестр этажей. ТОЛЬКО базовое: Get/Set/IsVisited/CanSwitch/EnsureStorage.
--
-- Generate / Clear / Switch здесь НЕ определяются:
--   - Generate — в Floors/Generate.lua
--   - Switch   — в Floors/Switch.lua
--   - SaveFloor / LoadFloor / ApplyWaterFromAbove / GetSnapshot — в Floors/Storage.lua
--
-- Если Generate.lua или Switch.lua не загрузятся — будет честная ошибка
-- «attempt to call method 'Generate' (a nil value)», а не тихий баг.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Floors = {}
    NSQC4.QuestsDfFloors = Floors

    Floors.FREE_FIRST   = true      -- 0 → -1 бесплатно
    Floors.VOID_PERCENT = 0.6       -- 60% для следующих переходов
    Floors.MAX_FLOOR    = 0         -- выше нулевого нельзя

    -- ========================================================================
    -- Хранилище (в nsDbc4)
    -- ========================================================================
    local function EnsureStorage()
        nsDbc4 = nsDbc4 or {}
        nsDbc4.quests = nsDbc4.quests or {}
        nsDbc4.quests.df = nsDbc4.quests.df or {}
        nsDbc4.quests.df.floors = nsDbc4.quests.df.floors or {}

        local s = nsDbc4.quests.df.floors
        s.current   = s.current or 0
        s.min       = s.min or 0
        s.max       = s.max or 0
        s.visited   = s.visited or { [0] = true }
        s.snapshots = s.snapshots or {}
        return s
    end

    function Floors:EnsureStorage() return EnsureStorage() end

    -- ========================================================================
    -- Текущий этаж
    -- ========================================================================
    function Floors:Get()
        return EnsureStorage().current
    end

    function Floors:Set(n)
        n = tonumber(n) or 0
        local s = EnsureStorage()
        s.current = n
        return true
    end

    function Floors:IsVisited(n)
        n = tonumber(n) or 0
        return EnsureStorage().visited[n] and true or false
    end

    -- ========================================================================
    -- CanSwitch(to) → true | false, reason
    -- ========================================================================
    function Floors:CanSwitch(to)
        to = tonumber(to) or 0
        local s = EnsureStorage()
        local cur = s.current

        if to == cur then
            return false, "уже на этом этаже"
        end

        if to > Floors.MAX_FLOOR then
            return false, "выше нулевого нельзя"
        end

        -- вниз
        if to < cur then
            -- 0 → -1 бесплатно
            if cur == 0 and to == -1 and Floors.FREE_FIRST then
                return true
            end
            -- иначе — нужно 60% void на текущем этаже
            local Void = NSQC4.QuestsDfTransformVoid
            if not Void then
                return false, "Void не загружен"
            end
            local pct = Void:PercentVoid()
            if pct < Floors.VOID_PERCENT then
                return false, string.format("нужно %.0f%% выкопано (сейчас %.0f%%)",
                    Floors.VOID_PERCENT * 100, pct * 100)
            end
            return true
        end

        -- вверх
        if to > cur then
            if s.visited[to] then
                return true
            end
            return false, "этаж не сгенерирован"
        end

        return false, "?"
    end

end)