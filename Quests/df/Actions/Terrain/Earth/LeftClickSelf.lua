-- ============================================================================
-- NSQC4 / Quests / df / Actions / Terrain / Earth / LeftClickSelf
-- ЛКМ по earth:
--   1. Есть активное (не спящее) существо → передаём существу (LeftClickEntities)
--   2. Нет существа / спит:
--      - есть лут → ничего не делаем (не выделяем)
--      - нет лута → toggle выделения ландшафта
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local A = NSQC4.QuestsDfTerrainActions
    if not A then
        print("|cffff0000[NSQC4]|r Earth/LeftClickSelf: Init.lua не загружен.")
        return
    end

    local QuestsField = NSQC4.QuestsField
    if not QuestsField then return end

    local Grid = NSQC4.QuestsDfGrid

    A.Types["earth"] = A.Types["earth"] or {}

    A.Types["earth"].LeftClickSelf = function(index)
        index = tonumber(index) or 0
        if index < 1 then return false end

        QuestsField:SetCellOnMouseClick(index, "LeftButton", function(btn, button, idx)
            local Drops  = NSQC4.QuestsDfTransformDrops
            local entity = Grid and Grid:GetEntity(idx)
            local sleeping = entity and entity.opts and entity.opts.sleeping

            -- 1. Активное существо → ему
            if entity and not sleeping then
                local T = NSQC4.QuestsDfTerrainActions
                          and NSQC4.QuestsDfTerrainActions.Types
                          and NSQC4.QuestsDfTerrainActions.Types["earth"]
                if T and T.LeftClickEntities then
                    return T.LeftClickEntities(idx)
                end
                return false
            end

            -- 2. Нет существа / спит → если лут, не выделяем
            local hasLoot = Drops and Drops:HasAny(idx) or false
            if hasLoot then
                return false
            end

            -- 3. Иначе — toggle выделения
            local cell = QuestsField.cells and QuestsField.cells[idx]
            if not Grid then return false end

            local isSelected = Grid:IsTerrainSelected(idx)

            if isSelected then
                Grid:SetTerrainSelected(idx, "earth", false)
                if cell and cell.texture then
                    cell.texture:SetVertexColor(1, 1, 1, 1)
                end
                print("|cffff8800[NSQC4]|r Снято выделение earth в клетке " .. idx)
            else
                Grid:SetTerrainSelected(idx, "earth", true)
                if cell and cell.texture then
                    cell.texture:SetVertexColor(0.5, 0.5, 0.5, 1)
                end
                print("|cff00ff00[NSQC4]|r Выделено earth в клетке " .. idx)
            end

            return true
        end)

        return true
    end

end)