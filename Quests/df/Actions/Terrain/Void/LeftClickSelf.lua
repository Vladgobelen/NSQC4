-- ============================================================================
-- NSQC4 / Quests / df / Actions / Terrain / Void / LeftClickSelf
-- ЛКМ по void:
--   1. Есть активное существо → LeftClickEntities
--   2. Иначе → ничего (пустоту не выделяем, лут не трогаем)
--
-- Отличие от остальных типов: у void НЕТ toggle выделения. Поэтому
-- SetCellSelectTint здесь не нужен — тинт для void ставить нечему.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local A = NSQC4.QuestsDfTerrainActions
    if not A then
        print("|cffff0000[NSQC4]|r Void/LeftClickSelf: Init.lua не загружен.")
        return
    end

    local QuestsField = NSQC4.QuestsField
    if not QuestsField then return end

    local Grid = NSQC4.QuestsDfGrid

    A.Types["void"] = A.Types["void"] or {}

    A.Types["void"].LeftClickSelf = function(index)
        index = tonumber(index) or 0
        if index < 1 then return false end

        QuestsField:SetCellOnMouseClick(index, "LeftButton", function(btn, button, idx)
            local entity = Grid and Grid:GetEntity(idx)
            local sleeping = entity and entity.opts and entity.opts.sleeping

            if entity and not sleeping then
                local T = NSQC4.QuestsDfTerrainActions
                          and NSQC4.QuestsDfTerrainActions.Types
                          and NSQC4.QuestsDfTerrainActions.Types["void"]
                if T and T.LeftClickEntities then
                    return T.LeftClickEntities(idx)
                end
                return false
            end

            -- пустоту не выделяем, ничего не делаем
            return false
        end)

        return true
    end

end)