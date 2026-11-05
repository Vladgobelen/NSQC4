-- ============================================================================
-- NSQC4 / Quests / df / Floors / Generate
-- Генерация этажа.
--
--   n < 0  → earth/stone (случайно), затем вода «сверху» из snapshots[n+1],
--            затем обычная генерация реки/озера (SeedRiver/SeedLake),
--            без существ, без лута
--   n == 0 → текущая карта (не генерируем)
--   n > 0  → нельзя (выше нулевого нет)
--
-- ВОДА СВЕРХУ:
--   Floors:ApplyWaterFromAbove(n) берёт снимок этажа n+1 (если есть) и
--   для каждой клетки, где на этаже n+1 вода с depth >= 1, ставит на этаж n
--   тоже воду с depth = depth - 1. Где depth - 1 == 0 — ставит earth (дно).
--   Это даёт «проваливание» реки/озера с этажа 0 вниз на глубину.
--
-- 0. Animate:StopAll() — чтобы temp-текстуры старого этажа не остались.
-- 1. Очистить клетки (terrain=nil, hardness=nil, entityName=nil, loot=nil,
--    depth=nil) и выделения (terrain_types, reserved).
-- 2. Для n < 0 — заполнить earth/stone.
-- 3. ApplyWaterFromAbove(n) — вода с этажа n+1, если есть снимок.
-- 4. SeedRiver/SeedLake — обычная генерация воды (если доступна).
-- 5. Пометить visited[n] = true, обновить min/max.
-- 6. Сохранить снимок (SaveFloor).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Floors = NSQC4.QuestsDfFloors
    if not Floors then
        print("|cffff0000[NSQC4]|r Floors/Generate: Init.lua не загружен.")
        return
    end

    local Grid    = NSQC4.QuestsDfGrid
    local Terrain = NSQC4.QuestsDfTerrain
    local Entities = NSQC4.QuestsDfEntities
    local Drops   = NSQC4.QuestsDfTransformDrops

    local CONST = NSQC4.QuestsFieldConst
    local TOTAL = CONST and (CONST.COLS * CONST.ROWS) or 100

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
        s.snapshots = s.snapshots or {}
        return s
    end

    -- ========================================================================
    -- Очистка клеток + выделений (включая depth)
    -- ========================================================================
    local function ClearGrid()
        if not Grid then return end
        for i = 1, TOTAL do
            local c = Grid:GetCell(i)
            if c then
                c.terrain    = nil
                c.hardness   = nil
                c.entityName = nil
                c.loot       = nil
                c.depth      = nil
            end
        end
        -- выделения: свои на каждом этаже, новый этаж — без выделений
        if Grid.ClearAllSelections then
            Grid:ClearAllSelections("terrain")
            Grid:ClearAllSelections("reserved")
        end
    end

    local function FillRandom(types)
        if not Terrain then return end
        for i = 1, TOTAL do
            local t = types[math.random(#types)]
            Terrain:SetTerrain(i, t)
        end
    end

    -- ========================================================================
    -- Вода с этажа n+1 (если есть снимок). Делает:
    --   - клетка над нами water depth>=2 → у нас water, depth-1
    --   - клетка над нами water depth==1 → у нас earth (дно)
    --   - клетка над нами не water        → не трогаем (останется earth/stone)
    -- ========================================================================
    local function ApplyWaterFromAbove(n)
        if not Floors.ApplyWaterFromAbove then return 0 end
        return Floors:ApplyWaterFromAbove(n)
    end

    -- ========================================================================
    -- Обычная генерация воды на этаже (река/озеро).
    -- Вызывается только если у этажа нет «воды сверху», либо в дополнение
    -- к ней (по желанию). Сейчас: если ApplyWaterFromAbove ничего не
    -- поставил — пробуем SeedRiver/SeedLake. Если поставил — не добавляем,
    -- чтобы не перекрывать «провалившуюся» воду.
    -- ========================================================================
    local function SeedWaterOnFloor(n, placedFromAbove)
        if placedFromAbove > 0 then
            return 0
        end
        if not Terrain then return 0 end

        local made = 0
        if Terrain.SeedRiver then
            local ok, res = pcall(Terrain.SeedRiver, Terrain)
            if ok and type(res) == "number" then made = made + res end
        end
        if Terrain.SeedLake then
            local ok, res = pcall(Terrain.SeedLake, Terrain)
            if ok and type(res) == "number" then made = made + res end
        end
        return made
    end

    -- ========================================================================
    -- Generate(n)
    -- ========================================================================
    function Floors:Generate(n)
        n = tonumber(n) or 0

        local s = EnsureStorage()
        if s.visited[n] and n ~= 0 then
            return false
        end

        if n > Floors.MAX_FLOOR then
            print("|cffff0000[NSQC4]|r Нельзя генерировать этаж выше нулевого.")
            return false
        end

        -- 0. Оборвать все анимации (temp на старом этаже)
        local Animate = NSQC4.QuestsDfEntitiesAnimate
        if Animate and Animate.StopAll then
            Animate:StopAll()
        end

        -- существ убираем на любом этаже (кроме 0 — там текущая карта)
        if n ~= 0 and Entities and Entities.Clear then
            Entities:Clear()
        end

        ClearGrid()

        if n < 0 then
            -- 2. База: земля/камень
            FillRandom({ "earth", "stone" })

            -- 3. Вода «сверху» (если этаж n+1 уже сгенерирован)
            local placedAbove = ApplyWaterFromAbove(n)

            -- 4. Обычная генерация воды — только если сверху ничего не пришло
            local placedSeed = SeedWaterOnFloor(n, placedAbove)

            if placedAbove > 0 or placedSeed > 0 then
                print(string.format(
                    "|cff00ffff[GEN]|r Этаж %d: вода сверху=%d, своя=%d",
                    n, placedAbove, placedSeed))
            end
        elseif n == 0 then
            -- текущая карта не генерируется
        end

        s.visited[n] = true
        if n < s.min then s.min = n end
        if n > s.max then s.max = n end

        if Floors.SaveFloor then
            Floors:SaveFloor(n)
        end

        if Terrain and Terrain.Render then Terrain:Render() end
        if Drops and Drops.RenderAll then Drops:RenderAll() end

        print(string.format("|cff00ff00[NSQC4]|r Этаж %d сгенерирован.", n))
        return true
    end

end)