-- ============================================================================
-- NSQC4 / Quests / df / Floors / Generate
-- Генерация этажа.
--
--   n < 0  → только earth/stone (случайно), без существ, без лута
--   n == 0 → текущая карта (не генерируем)
--   n > 0  → нельзя (выше нулевого нет)
--
-- Floors:Generate(n):
--   1. Очистить клетки (terrain=nil, hardness=nil, entityName=nil, loot=nil)
--   2. Для n < 0 — заполнить earth/stone (50/50 или по вкусу)
--   3. Пометить visited[n] = true, обновить min/max
--   4. Сохранить снимок (SaveFloor)
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

    local function ClearGrid()
        if not Grid then return end
        for i = 1, TOTAL do
            local c = Grid:GetCell(i)
            if c then
                c.terrain    = nil
                c.hardness   = nil
                c.entityName = nil
                c.loot       = nil
            end
        end
        -- снять выделения
        if Grid.ClearAllSelections then
            Grid:ClearAllSelections("terrain")
        end
    end

    local function FillRandom(types)
        if not Terrain then return end
        for i = 1, TOTAL do
            local t = types[math.random(#types)]
            Terrain:SetTerrain(i, t)
        end
    end

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

        -- существ убираем на любом этаже (кроме 0 — там текущая карта)
        if n ~= 0 and Entities and Entities.Clear then
            Entities:Clear()
        end

        ClearGrid()

        if n < 0 then
            FillRandom({ "earth", "stone" })
        elseif n == 0 then
            -- текущая карта не генерируется
        end

        s.visited[n] = true
        if n < s.min then s.min = n end
        if n > s.max then s.max = n end

        -- снимок
        if Floors.SaveFloor then
            Floors:SaveFloor(n)
        end

        -- перерисовать
        if Terrain and Terrain.Render then Terrain:Render() end
        if Drops and Drops.RenderAll then Drops:RenderAll() end

        print(string.format("|cff00ff00[NSQC4]|r Этаж %d сгенерирован.", n))
        return true
    end

end)