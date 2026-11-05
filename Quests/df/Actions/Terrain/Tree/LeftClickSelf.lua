-- ============================================================================
-- NSQC4 / Quests / df / Actions / Terrain / Tree / LeftClickSelf
-- ЛКМ по tree:
--   1. Есть активное существо → LeftClickEntities
--   2. Нет существа / спит:
--      - есть лут → ничего (не выделяем)
--      - нет лута → toggle выделения tree
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local A = NSQC4.QuestsDfTerrainActions
    if not A then
        print("|cffff0000[NSQC4]|r Tree/LeftClickSelf: Init.lua не загружен.")
        return
    end

    local QuestsField = NSQC4.QuestsField
    if not QuestsField then return end

    local Grid = NSQC4.QuestsDfGrid

    A.Types["tree"] = A.Types["tree"] or {}

    A.Types["tree"].LeftClickSelf = function(index)
        index = tonumber(index) or 0
        if index < 1 then return false end

        QuestsField:SetCellOnMouseClick(index, "LeftButton", function(btn, button, idx)
            local Drops  = NSQC4.QuestsDfTransformDrops
            local entity = Grid and Grid:GetEntity(idx)
            local sleeping = entity and entity.opts and entity.opts.sleeping

            if entity and not sleeping then
                local T = NSQC4.QuestsDfTerrainActions
                          and NSQC4.QuestsDfTerrainActions.Types
                          and NSQC4.QuestsDfTerrainActions.Types["tree"]
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
                Grid:SetTerrainSelected(idx, "tree", false)
                if cell and cell.texture then
                    cell.texture:SetVertexColor(1, 1, 1, 1)
                end
                print("|cffff8800[NSQC4]|r Снято выделение tree в клетке " .. idx)
            else
                Grid:SetTerrainSelected(idx, "tree", true)
                if cell and cell.texture then
                    cell.texture:SetVertexColor(0.5, 0.5, 0.5, 1)
                end
                print("|cff00ff00[NSQC4]|r Выделено tree в клетке " .. idx)
            end

            return true
        end)

        return true
    end

end)