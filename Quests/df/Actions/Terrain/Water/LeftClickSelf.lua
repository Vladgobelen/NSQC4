-- ============================================================================
-- NSQC4 / Quests / df / Actions / Terrain / Water / LeftClickSelf
-- ЛКМ по воде:
--   1. Есть активное (не спящее) существо → передаём существу (LeftClickEntities)
--   2. Иначе → toggle выделения воды (как у Earth/Grass/Stone/Tree/Pool)
--      + печать-заглушка «работа на воде: TODO» (по ТЗ)
--
-- Лут на воде пока не предусмотрен — проверку Drops:HasAny не делаем.
--
-- ВЫДЕЛЕНИЕ С ОТТЕНКОМ:
--   Цвет задаёт сам объект (SELECT_TINT), поле только красит
--   (QuestsField:SetCellSelectTint). При де-выделении поле снимает тинт
--   само (Grid:SetTerrainSelected(..., false)).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local A = NSQC4.QuestsDfTerrainActions
    if not A then
        print("|cffff0000[NSQC4]|r Water/LeftClickSelf: Init.lua не загружен.")
        return
    end

    local QuestsField = NSQC4.QuestsField
    if not QuestsField then return end

    local Grid = NSQC4.QuestsDfGrid

    -- Цвет выделения water — голубой.
    local SELECT_TINT = { 0.30, 0.70, 1.00, 1.0 }

    A.Types["water"] = A.Types["water"] or {}

    A.Types["water"].LeftClickSelf = function(index)
        index = tonumber(index) or 0
        if index < 1 then return false end

        QuestsField:SetCellOnMouseClick(index, "LeftButton", function(btn, button, idx)
            local entity = Grid and Grid:GetEntity(idx)
            local sleeping = entity and entity.opts and entity.opts.sleeping

            -- 1. Активное существо → ему
            if entity and not sleeping then
                local T = NSQC4.QuestsDfTerrainActions
                          and NSQC4.QuestsDfTerrainActions.Types
                          and NSQC4.QuestsDfTerrainActions.Types["water"]
                if T and T.LeftClickEntities then
                    return T.LeftClickEntities(idx)
                end
                return false
            end

            -- 2. Нет существа / спит → toggle выделения воды
            if not Grid then return false end

            local isSelected = Grid:IsTerrainSelected(idx)

            if isSelected then
                Grid:SetTerrainSelected(idx, "water", false)
                print("|cffff8800[NSQC4]|r Снято выделение water в клетке " .. idx)
            else
                Grid:SetTerrainSelected(idx, "water", true)
                QuestsField:SetCellSelectTint(idx,
                    SELECT_TINT[1], SELECT_TINT[2], SELECT_TINT[3], SELECT_TINT[4])

                -- Глубина для печати (безопасно: если GetDepth ещё не загружен — "?")
                local depth = "?"
                if Grid.GetDepth then
                    depth = Grid:GetDepth(idx) or "?"
                end

                print("|cff00ff00[NSQC4]|r Выделено water в клетке " .. idx ..
                      " (глубина " .. tostring(depth) .. "; работа на воде: TODO)")
            end

            return true
        end)

        return true
    end

end)