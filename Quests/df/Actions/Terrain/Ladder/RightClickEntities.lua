-- ============================================================================
-- NSQC4 / Quests / df / Actions / Terrain / Ladder / RightClickEntities
-- ПКМ по ladder. Флаг demolish УБРАН.
--
--   1. Существо → меню существа.
--   2. Лут → меню не показываем.
--   3. Меню клетки:
--        hp >= max → «Готова: X/Y», «Спуститься», «Подняться», «Сломать лестницу»
--        hp <  max → «Строится: X/Y (Z%)» + «Сломать лестницу»
--
-- «Сломать лестницу» — МГНОВЕННО: hp = 0, RemoveBuilding, void, материал 10.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local A = NSQC4.QuestsDfTerrainActions
    if not A then
        print("|cffff0000[NSQC4]|r Ladder/RightClickEntities: Init.lua не загружен.")
        return
    end

    local QuestsField = NSQC4.QuestsField
    if not QuestsField then return end

    local Grid = NSQC4.QuestsDfGrid

    -- ========================================================================
    -- Вспомогательное
    -- ========================================================================
    local function OwnerName(b)
        if not b or not b.by then return nil end
        if b.byName then return b.byName end
        local E = NSQC4.QuestsDfEntities
        if E and E.Get then
            local e = E:Get(b.by)
            if e and e.opts and e.opts.name then return e.opts.name end
        end
        return tostring(b.by)
    end

    local function RenderCell(idx)
        local TerrainApi = NSQC4.QuestsDfTerrainUIApi
        if TerrainApi and TerrainApi.RenderCellFromStorage then
            TerrainApi:RenderCellFromStorage(idx)
        end
    end

    -- ========================================================================
    -- «Сломать лестницу» — МГНОВЕННО.
    -- ========================================================================
    local function ActionDemolish(idx)
        local b = Grid:GetBuilding(idx)
        local material = b and b.material or "wood"
        local totalHP  = b and tonumber(b.max) or 1000

        -- освободить от того, кто строит/ломает
        local _, by = Grid:GetBuildingOwner(idx)
        if by then Grid:ReleaseBuilding(idx, by) end

        -- материал 10 в соседние
        local Drops = NSQC4.QuestsDfTransformDrops
        if Drops then
            local Data = NSQC4.QuestsDfTerrainData
            local icon = (Data and Data:Get(material) and Data:Get(material).texture) or nil
            local count = math.max(0, math.floor(totalHP / 100))
            local neighbors = Grid:Neighbors(idx)
            for _ = 1, count do
                for _try = 1, #neighbors do
                    local n = neighbors[math.random(#neighbors)]
                    local c = Grid:GetCell(n)
                    if c and c.terrain ~= "void" then
                        if Drops:Add(n, material, icon) then break end
                    end
                end
            end
        end

        -- удалить постройку, снять выделение, клетка → void
        Grid:SetHardness(idx, 0)
        Grid:RemoveBuilding(idx)
        Grid:SetTerrainSelected(idx, "ladder", false)

        local Terrain = NSQC4.QuestsDfTerrain
        if Terrain and Terrain.SetTerrain then
            Terrain:SetTerrain(idx, "void")
        end

        RenderCell(idx)
        print("|cffff8800[NSQC4]|r Лестница сломана (клетка " .. idx .. ").")
    end

    A.Types["ladder"] = A.Types["ladder"] or {}

    A.Types["ladder"].RightClickEntities = function(index)
        index = tonumber(index) or 0
        if index < 1 then return false end

        QuestsField:SetCellOnMouseClick(index, "RightButton", function(btn, button, idx)
            local Drops  = NSQC4.QuestsDfTransformDrops
            local entity = Grid and Grid:GetEntity(idx)
            local hasEntity = entity ~= nil
            local sleeping  = entity and entity.opts and entity.opts.sleeping
            local hasLoot   = Drops and Drops:HasAny(idx) or false

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
                            if Entities then Entities:Spawn(entity.id, idx, opts) end
                            print("|cff00ff00[NSQC4]|r " .. (opts.name or "Существо") .. " проснулся.")
                        end,
                    }
                else
                    menuItems[#menuItems + 1] = {
                        text = "Спать",
                        func = function()
                            opts.sleeping = true
                            local Entities = NSQC4.QuestsDfEntities
                            if Entities then Entities:Spawn(entity.id, idx, opts) end
                            print("|cff00ff00[NSQC4]|r " .. (opts.name or "Существо") .. " уснул.")
                        end,
                    }
                end

                menuItems[#menuItems + 1] = {
                    text = "Осмотреть",
                    func = function()
                        print("|cff00ff00[NSQC4]|r Вы осмотрели " .. (opts.name or "существо") .. ".")
                    end,
                }

                QuestsField:ShowContextMenu(menuItems, btn)
                return true
            end

            -- 2. Существа нет, есть лут → меню не показываем
            if hasLoot then return false end

            -- 3. Меню клетки (по hp/max)
            local b   = Grid and Grid:GetBuilding(idx)
            local hp  = b and tonumber(b.hp)  or 0
            local max = b and tonumber(b.max) or 1000
            local owner = OwnerName(b)

            local menuItems = {}

            if hp >= max then
                -- готова
                menuItems[#menuItems + 1] = {
                    text = string.format("Готова: %d / %d", math.floor(hp + 0.5), math.floor(max + 0.5)),
                    func = function() print("|cff00ff00[NSQC4]|r Лестница готова (клетка " .. idx .. ")") end,
                }
                menuItems[#menuItems + 1] = {
                    text = "Спуститься",
                    func = function()
                        local Floors = NSQC4.QuestsDfFloors
                        if not Floors then return end
                        Floors:Switch(Floors:Get() - 1)
                    end,
                }
                menuItems[#menuItems + 1] = {
                    text = "Подняться",
                    func = function()
                        local Floors = NSQC4.QuestsDfFloors
                        if not Floors then return end
                        Floors:Switch(Floors:Get() + 1)
                    end,
                }
                menuItems[#menuItems + 1] = {
                    text = "Сломать лестницу",
                    func = function() ActionDemolish(idx) end,
                }
            else
                -- строится
                local pct = (max > 0) and (hp / max * 100) or 0
                local progress
                if owner then
                    progress = string.format("Строится: %d / %d (%.0f%%) — строит: %s",
                        math.floor(hp + 0.5), math.floor(max + 0.5), pct, owner)
                else
                    progress = string.format("Строится: %d / %d (%.0f%%) — ждёт строителя",
                        math.floor(hp + 0.5), math.floor(max + 0.5), pct)
                end
                menuItems[#menuItems + 1] = {
                    text = progress,
                    func = function() print("|cffffaa00[NSQC4]|r " .. progress) end,
                }
                menuItems[#menuItems + 1] = {
                    text = "Сломать лестницу",
                    func = function() ActionDemolish(idx) end,
                }
            end

            QuestsField:ShowContextMenu(menuItems, btn)
            return true
        end)

        return true
    end

end)