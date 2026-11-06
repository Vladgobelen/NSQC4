-- ============================================================================
-- NSQC4 / Quests / df / Actions / Terrain / Stone / LeftClickSelf
-- ЛКМ по stone:
--   1. Есть активное существо → LeftClickEntities
--   2. Нет существа / спит:
--      - есть лут → ничего (не выделяем)
--      - нет лута → toggle выделения stone
--
-- ВЫДЕЛЕНИЕ С ОТТЕНКОМ:
--   Цвет задаёт сам объект (SELECT_TINT), поле только красит
--   (QuestsField:SetCellSelectTint). При де-выделении поле снимает тинт
--   само (Grid:SetTerrainSelected(..., false)).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local A = NSQC4.QuestsDfTerrainActions
    if not A then
        print("|cffff0000[NSQC4]|r Stone/LeftClickSelf: Init.lua не загружен.")
        return
    end

    local QuestsField = NSQC4.QuestsField
    if not QuestsField then return end

    local Grid = NSQC4.QuestsDfGrid

    -- Цвет выделения stone — серый.
    local SELECT_TINT = { 0.60, 0.60, 0.60, 1.0 }

    A.Types["stone"] = A.Types["stone"] or {}

    A.Types["stone"].LeftClickSelf = function(index)
        index = tonumber(index) or 0
        if index < 1 then return false end

        QuestsField:SetCellOnMouseClick(index, "LeftButton", function(btn, button, idx)
            local Drops  = NSQC4.QuestsDfTransformDrops
            local entity = Grid and Grid:GetEntity(idx)
            local sleeping = entity and entity.opts and entity.opts.sleeping

            if entity and not sleeping then
                local T = NSQC4.QuestsDfTerrainActions
                          and NSQC4.QuestsDfTerrainActions.Types
                          and NSQC4.QuestsDfTerrainActions.Types["stone"]
                if T and T.LeftClickEntities then
                    return T.LeftClickEntities(idx)
                end
                return false
            end

            local hasLoot = Drops and Drops:HasAny(idx) or false
            if hasLoot then
                return false
            end

            if not Grid then return false end

            local isSelected = Grid:IsTerrainSelected(idx)

            if isSelected then
                Grid:SetTerrainSelected(idx, "stone", false)
                print("|cffff8800[NSQC4]|r Снято выделение stone в клетке " .. idx)
            else
                Grid:SetTerrainSelected(idx, "stone", true)
                QuestsField:SetCellSelectTint(idx,
                    SELECT_TINT[1], SELECT_TINT[2], SELECT_TINT[3], SELECT_TINT[4])
                print("|cff00ff00[NSQC4]|r Выделено stone в клетке " .. idx)
            end

            return true
        end)

        return true
    end

end)