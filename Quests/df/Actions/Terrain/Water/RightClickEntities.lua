-- ============================================================================
-- NSQC4 / Quests / df / Actions / Terrain / Water / RightClickEntities
-- ПКМ по воде.
--
-- ЛОГИКА (по ТЗ «ПКМ по воде пустой» + меню существа):
--   1. Есть существо (активное ИЛИ спящее) → меню существа:
--        - «Спать» / «Разбудить»
--        - «Осмотреть»
--      Меню показываем даже если есть лут — иначе нельзя разбудить
--      существо на воде (например, пловца, который уснул).
--   2. Существа нет → ничего (меню клетки нет, по ТЗ ПКМ по воде пустой).
--
-- ВАЖНО: раньше файл делал SetCellOnMouseClick(index, "RightButton", nil) —
-- это СНИМАЛО ПКМ-обработчик, и меню существа (если оно на воде) не
-- появлялось. Теперь вешаем обработчик, который сам решает.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local A = NSQC4.QuestsDfTerrainActions
    if not A then
        print("|cffff0000[NSQC4]|r Water/RightClickEntities: Init.lua не загружен.")
        return
    end

    local QuestsField = NSQC4.QuestsField
    if not QuestsField then return end

    local Grid = NSQC4.QuestsDfGrid

    A.Types["water"] = A.Types["water"] or {}

    A.Types["water"].RightClickEntities = function(index)
        index = tonumber(index) or 0
        if index < 1 then return false end

        QuestsField:SetCellOnMouseClick(index, "RightButton", function(btn, button, idx)
            local entity = Grid and Grid:GetEntity(idx)
            local hasEntity = entity ~= nil
            local sleeping  = entity and entity.opts and entity.opts.sleeping

            -- 1. Существо → меню существа
            if hasEntity and entity.opts then
                local opts = entity.opts
                local menuItems = {}

                if sleeping then
                    menuItems[#menuItems + 1] = {
                        text = "Разбудить",
                        func = function()
                            opts.sleeping = false
                            local Entities = NSQC4.QuestsDfEntities
                            if Entities then
                                Entities:Spawn(entity.id, idx, opts)
                            end
                            print("|cff00ff00[NSQC4]|r " ..
                                  (opts.name or "Существо") .. " проснулся.")
                        end,
                    }
                else
                    menuItems[#menuItems + 1] = {
                        text = "Спать",
                        func = function()
                            opts.sleeping = true
                            local Entities = NSQC4.QuestsDfEntities
                            if Entities then
                                Entities:Spawn(entity.id, idx, opts)
                            end
                            print("|cff00ff00[NSQC4]|r " ..
                                  (opts.name or "Существо") .. " уснул.")
                        end,
                    }
                end

                menuItems[#menuItems + 1] = {
                    text = "Осмотреть",
                    func = function()
                        print("|cff00ff00[NSQC4]|r Вы осмотрели " ..
                              (opts.name or "существо") .. ".")
                    end,
                }

                QuestsField:ShowContextMenu(menuItems, btn)
                return true
            end

            -- 2. Существа нет → меню клетки нет (по ТЗ ПКМ по воде пустой)
            return false
        end)

        return true
    end

end)