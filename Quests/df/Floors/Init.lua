-- ============================================================================
-- NSQC4 / Quests / df / Floors / Init
-- Реестр этажей.
--
-- Модель:
--   nsDbc4.quests.df.floors = {
--     current = 0,
--     min     = -N,   -- самый нижний сгенерированный этаж
--     max     = 0,    -- выше нулевого нельзя
--     visited = { [0] = true, [-1] = true, ... },
--   }
--
-- API:
--   Floors:Get()           → текущий этаж
--   Floors:Set(n)          → установить (без генерации)
--   Floors:CanSwitch(to)   → true/false + причина
--   Floors:Switch(to)      → переключить (с проверкой)
--   Floors:Generate(n)     → сгенерировать этаж n (если ещё нет)
--   Floors:Clear(n)        → очистить этаж n
--   Floors:IsVisited(n)    → true, если этаж уже сгенерирован
--
-- Логика переключения:
--   - бесплатно только 0 → -1
--   - дальше — только если PercentVoid() >= 0.6 (60% выкопано)
--   - выше 0 нельзя
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
        s.current = s.current or 0
        s.min     = s.min or 0
        s.max     = s.max or 0
        s.visited = s.visited or { [0] = true }
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
            -- возврат на посещённый этаж — бесплатно
            if s.visited[to] then
                return true
            end
            return false, "этаж не сгенерирован"
        end

        return false, "?"
    end

    -- ========================================================================
    -- Generate(n) — сгенерировать этаж (заглушка: пока просто помечаем visited;
    -- реальная генерация — в Floors/Generate.lua)
    -- ========================================================================
    function Floors:Generate(n)
        n = tonumber(n) or 0
        local s = EnsureStorage()
        if s.visited[n] then return false end
        s.visited[n] = true
        if n < s.min then s.min = n end
        return true
    end

    -- ========================================================================
    -- Clear(n) — очистить этаж (заглушка)
    -- ========================================================================
    function Floors:Clear(n)
        n = tonumber(n) or 0
        local s = EnsureStorage()
        s.visited[n] = nil
        return true
    end

    -- ========================================================================
    -- Switch(to) — переключить (с проверкой CanSwitch)
    -- ========================================================================
    function Floors:Switch(to)
        to = tonumber(to) or 0
        local ok, reason = self:CanSwitch(to)
        if not ok then
            print("|cffff0000[NSQC4]|r Нельзя переключить этаж: " .. tostring(reason))
            return false
        end

        -- сохранить текущий этаж (позже — Storage)
        local s = EnsureStorage()
        local from = s.current

        -- сгенерировать целевой этаж, если ещё нет
        if not s.visited[to] then
            self:Generate(to)
        end

        s.current = to
        print(string.format("|cff00ff00[NSQC4]|r Этаж: %d → %d", from, to))
        return true
    end

end)