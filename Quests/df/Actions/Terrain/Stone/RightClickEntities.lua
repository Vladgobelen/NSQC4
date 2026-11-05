-- ============================================================================
-- NSQC4 / Quests / df / Actions / Terrain / Stone / RightClickEntities
-- ПКМ по существу в клетке с "stone".
-- Вызывается из Check.lua, когда есть существо (не спит).
--
-- Регистрирует ПКМ на клетке через Mouse. При клике:
--   - есть существо → меню существа (Спать/Разбудить/Осмотреть)
--   - нет существа  → ничего
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local A = NSQC4.QuestsDfTerrainActions
    if not A then
        print("|cffff0000[NSQC4]|r Stone/RightClickEntities: Init.lua не загружен.")
        return
    end

    local QuestsField = NSQC4.QuestsField
    if not QuestsField then return end

    local Grid = NSQC4.QuestsDfGrid

    A.Types["stone"] = A.Types["stone"] or {}

    A.Types["stone"].RightClickEntities = function(index)
        index = tonumber(index) or 0
        if index < 1 then return false end

        QuestsField:SetCellOnMouseClick(index, "RightButton", function(btn, button, idx)
            -- 1. Есть ли существо?
            local entity = Grid and Grid:GetEntity(idx)
            if not entity or not entity.opts then
                return false   -- нет — ничего
            end

            -- 2. Меню существа
            local opts = entity.opts
            local menuItems = {}

            if opts.sleeping then
                menuItems[#menuItems + 1] = {
                    text = "Разбудить",
                    func = function()
                        opts.sleeping = false
                        local Entities = NSQC4.QuestsDfEntities
                        if Entities then Entities:Spawn(entity.id, idx, opts) end
                    end
                }
            else
                menuItems[#menuItems + 1] = {
                    text = "Спать",
                    func = function()
                        opts.sleeping = true
                        local Entities = NSQC4.QuestsDfEntities
                        if Entities then Entities:Spawn(entity.id, idx, opts) end
                    end
                }
            end

            menuItems[#menuItems + 1] = {
                text = "Осмотреть",
                func = function()
                    print("|cff00ff00[NSQC4]|r Вы осмотрели " ..
                          (opts.name or "существо") .. ".")
                end
            }

            QuestsField:ShowContextMenu(menuItems, btn)
            return true
        end)

        return true
    end

end)