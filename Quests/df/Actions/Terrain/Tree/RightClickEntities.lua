-- ============================================================================
-- NSQC4 / Quests / df / Actions / Terrain / Tree / RightClickEntities
-- ПКМ по tree:
--   1. Есть лут и нет активного существа → меню не показываем
--   2. Есть активное существо → меню существа (Спать/Осмотреть)
--   3. Иначе → меню нет
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local A = NSQC4.QuestsDfTerrainActions
    if not A then
        print("|cffff0000[NSQC4]|r Tree/RightClickEntities: Init.lua не загружен.")
        return
    end

    local QuestsField = NSQC4.QuestsField
    if not QuestsField then return end

    local Grid = NSQC4.QuestsDfGrid

    A.Types["tree"] = A.Types["tree"] or {}

    A.Types["tree"].RightClickEntities = function(index)
        index = tonumber(index) or 0
        if index < 1 then return false end

        QuestsField:SetCellOnMouseClick(index, "RightButton", function(btn, button, idx)
            local Drops  = NSQC4.QuestsDfTransformDrops
            local entity = Grid and Grid:GetEntity(idx)
            local sleeping = entity and entity.opts and entity.opts.sleeping
            local hasActive = entity and not sleeping
            local hasLoot = Drops and Drops:HasAny(idx) or false

            if hasLoot and not hasActive then
                return false
            end

            if hasActive then
                local opts = entity.opts
                local menuItems = {
                    { text = "Спать", func = function()
                        opts.sleeping = true
                        local Entities = NSQC4.QuestsDfEntities
                        if Entities then Entities:Spawn(entity.id, idx, opts) end
                    end },
                    { text = "Осмотреть", func = function()
                        print("|cff00ff00[NSQC4]|r Вы осмотрели " ..
                              (opts.name or "существо") .. ".")
                    end },
                }
                QuestsField:ShowContextMenu(menuItems, btn)
                return true
            end

            return false   -- меню нет
        end)

        return true
    end

end)