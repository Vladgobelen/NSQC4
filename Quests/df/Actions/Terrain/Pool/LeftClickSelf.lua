-- ============================================================================
-- NSQC4 / Quests / df / Actions / Terrain / Pool / LeftClickSelf
-- ЛКМ по pool:
--   1. Есть активное существо → LeftClickEntities
--   2. Нет существа / спит:
--      - есть лут → ничего (не выделяем)
--      - нет лута → toggle выделения pool
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local A = NSQC4.QuestsDfTerrainActions
    if not A then
        print("|cffff0000[NSQC4]|r Pool/LeftClickSelf: Init.lua не загружен.")
        return
    end

    local QuestsField = NSQC4.QuestsField
    if not QuestsField then return end

    local Grid = NSQC4.QuestsDfGrid

    A.Types["pool"] = A.Types["pool"] or {}

    A.Types["pool"].LeftClickSelf = function(index)
        index = tonumber(index) or 0
        if index < 1 then return false end

        QuestsField:SetCellOnMouseClick(index, "LeftButton", function(btn, button, idx)
            local Drops  = NSQC4.QuestsDfTransformDrops
            local entity = Grid and Grid:GetEntity(idx)
            local sleeping = entity and entity.opts and entity.opts.sleeping

            if entity and not sleeping then
                local T = NSQC4.QuestsDfTerrainActions
                          and NSQC4.QuestsDfTerrainActions.Types
                          and NSQC4.QuestsDfTerrainActions.Types["pool"]
                if T and T.LeftClickEntities then
                    return T.LeftClickEntities(idx)
                end
                return false
            end

            local hasLoot = Drops and Drops:HasAny(idx) or false
            if hasLoot then
                return false
            end

            local cell = QuestsField.cells and QuestsField.cells[idx]
            if not Grid then return false end

            local isSelected = Grid:IsTerrainSelected(idx)

            if isSelected then
                Grid:SetTerrainSelected(idx, "pool", false)
                if cell and cell.texture then
                    cell.texture:SetVertexColor(1, 1, 1, 1)
                end
                print("|cffff8800[NSQC4]|r Снято выделение pool в клетке " .. idx)
            else
                Grid:SetTerrainSelected(idx, "pool", true)
                if cell and cell.texture then
                    cell.texture:SetVertexColor(0.5, 0.5, 0.5, 1)
                end
                print("|cff00ff00[NSQC4]|r Выделено pool в клетке " .. idx)
            end

            return true
        end)

        return true
    end

end)