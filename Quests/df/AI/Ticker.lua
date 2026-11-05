-- ============================================================================
-- NSQC4 / Quests / df / AI / Ticker
-- Один глобальный OnUpdate. Раз в INTERVAL секунд проходит по всем
-- клеткам Grid и для каждого существа зовёт AI:TickEntity(entity).
--
-- ПРИОРИТЕТ (два прохода):
--   1. withProf — существа, у которых есть «своя» профессия:
--        - под СТРОЙКУ (builder) — если есть недостроенные buildings;
--        - под выделенную клетку (Find:HasProfForSelected).
--      Они тикают ПЕРВЫМИ и резервируют «свои» клетки (buildings).
--   2. withoutProf — все остальные. Им достаётся то, что осталось.
--
-- ФИКС: frame:Show() в EnsureFrame — без Show OnUpdate не тикает.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local AI = NSQC4.QuestsDfAI
    if not AI then
        print("|cffff0000[NSQC4]|r AI/Ticker: AI/Init.lua не загружен.")
        return
    end

    local CONST = NSQC4.QuestsFieldConst
    if not CONST then return end
    local TOTAL = CONST.COLS * CONST.ROWS

    local Grid = NSQC4.QuestsDfGrid
    if not Grid then
        print("|cffff0000[NSQC4]|r AI/Ticker: Grid не загружен.")
        return
    end

    local Ticker = {}
    NSQC4.QuestsDfAITicker = Ticker

    local frame       = nil
    local accumulator = 0

    local function EnsureFrame()
        if frame then return frame end
        frame = CreateFrame("Frame")
        frame:SetScript("OnUpdate", function(_, elapsed)
            accumulator = accumulator + elapsed
            if accumulator < AI.INTERVAL then return end
            accumulator = accumulator - AI.INTERVAL
            Ticker:Tick()
        end)
        frame:Show()   -- ФИКС: без Show OnUpdate не тикает
        return frame
    end

    function Ticker:Tick()
        local Find = NSQC4.QuestsDfAIFind
        local withProf, withoutProf = {}, {}

        -- Есть ли недостроенные постройки?
        local hasBuildings = false
        if Grid.GetAllBuildings then
            local b = Grid:GetAllBuildings()
            for _, rec in pairs(b) do
                if rec and tonumber(rec.hp) and tonumber(rec.max) and rec.hp < rec.max then
                    hasBuildings = true
                    break
                end
            end
        end

        -- 1. Разделяем существ на две группы
        for i = 1, TOTAL do
            local entity = Grid:GetEntity(i)
            if entity and entity.opts then
                local hasProf = false
                if Find and Find.HasProfForSelected then
                    hasProf = Find:HasProfForSelected(entity)
                end
                if hasProf then
                    withProf[#withProf + 1] = entity
                else
                    withoutProf[#withoutProf + 1] = entity
                end
            end
        end

        -- 2. Сначала тикают «профи» — они забирают свои клетки
        for _, entity in ipairs(withProf) do
            AI:TickEntity(entity)
        end

        -- 3. Потом все остальные — берут что осталось
        for _, entity in ipairs(withoutProf) do
            AI:TickEntity(entity)
        end
    end

    function Ticker:Start()
        EnsureFrame()
    end

end)