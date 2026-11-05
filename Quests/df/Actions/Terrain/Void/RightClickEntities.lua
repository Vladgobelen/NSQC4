-- ============================================================================
-- NSQC4 / Quests / df / Actions / Terrain / Void / RightClickEntities
-- ПКМ по void.
--
-- ЛОГИКА:
--   1. Есть существо (активное ИЛИ спящее) → меню существа:
--        - «Спать» / «Разбудить»
--        - «Осмотреть»
--   2. Существа нет и есть лут → меню не показываем (return false).
--   3. Существа нет и лута нет → меню клетки:
--        - «Постройка лестницы» → ПОДМЕНЮ материалов:
--            * wood  (если на карте >= MATERIALS_PER_LADDER)
--            * stone (если на карте >= MATERIALS_PER_LADDER)
--          Если ни одного материала не хватает — пункт «Нет материалов».
--          При выборе:
--            * ПРОВЕРКА ДОСТУПНОСТИ: у void должен быть хотя бы один
--              сосед с terrain ~= "void" (иначе существу некуда подойти).
--              Если нет — сообщение, постройка отменяется (П.4-цикл).
--            * terrain = "ladder"
--            * Grid:SetHardness(idx, 1)
--            * Grid:AddBuilding(idx, "ladder", 1000, material)
--            * иконка лестницы alpha 0.5, tint по материалу (в UI/Api)
--
-- П.4-цикл (быстро): проверка доступности убирает ситуацию, когда
-- существо каждую секунду выбирает недостижимую постройку (Find:Pick
-- возвращает её, Path:Find → nil, существо снова idle → цикл + ор).
-- Правильное решение (строить с соседней клетки, workTarget) — позже.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local A = NSQC4.QuestsDfTerrainActions
    if not A then
        print("|cffff0000[NSQC4]|r Void/RightClickEntities: Init.lua не загружен.")
        return
    end

    local QuestsField = NSQC4.QuestsField
    if not QuestsField then return end

    local Grid = NSQC4.QuestsDfGrid

    -- Сколько единиц материала нужно на одну лестницу (1000 HP / 100).
    local MATERIALS_PER_LADDER = 10

    -- Какие материалы годятся для лестницы.
    -- id — как в Transform/Data (drop), label — как в тултипе.
    local LADDER_MATERIALS = {
        { id = "wood",  label = "Дерево" },
        { id = "stone", label = "Камень" },
    }

    -- ========================================================================
    -- Есть ли у клетки хотя бы один проходимый сосед (terrain ~= "void").
    -- Без этого существу некуда подойти (лестница в глубине void).
    -- ========================================================================
    local function HasReachableNeighbor(index)
        if not Grid then return false end
        local neighbors = Grid:Neighbors(index)
        for _, n in ipairs(neighbors) do
            local c = Grid:GetCell(n)
            if c and c.terrain ~= "void" then
                return true
            end
        end
        return false
    end

    -- ========================================================================
    -- Собрать доступные материалы (id + label + count).
    -- Только те, у которых count >= MATERIALS_PER_LADDER.
    -- ========================================================================
    local function CollectAvailableMaterials()
        local Drops = NSQC4.QuestsDfTransformDrops
        if not Drops or not Drops.CountAllById then return {} end

        local result = {}
        for _, m in ipairs(LADDER_MATERIALS) do
            local n = Drops:CountAllById(m.id)
            if n >= MATERIALS_PER_LADDER then
                result[#result + 1] = {
                    id    = m.id,
                    label = m.label,
                    count = n,
                }
            end
        end
        return result
    end

    A.Types["void"] = A.Types["void"] or {}

    A.Types["void"].RightClickEntities = function(index)
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

            -- 2. Существа нет, есть лут → меню не показываем
            if hasLoot then
                return false
            end

            -- 3. Существа нет, лута нет → меню клетки (лестница + материалы)
            local menuItems = {}

            -- 3.1. Проверка доступности (П.4-цикл, быстро)
            if not HasReachableNeighbor(idx) then
                menuItems[#menuItems + 1] = {
                    text = "Нет прохода: клетка окружена пустотой",
                    func = function()
                        print("|cffff0000[NSQC4]|r Нельзя построить лестницу: " ..
                              "клетка " .. idx .. " окружена пустотой (некуда подойти).")
                    end,
                }
                QuestsField:ShowContextMenu(menuItems, btn)
                return true
            end

            -- 3.2. Собрать доступные материалы
            local materials = CollectAvailableMaterials()

            if #materials == 0 then
                menuItems[#menuItems + 1] = {
                    text = string.format(
                        "Нет материалов (нужно %d дерева или камня)",
                        MATERIALS_PER_LADDER),
                    func = function()
                        print(string.format(
                            "|cffff0000[NSQC4]|r Нельзя построить лестницу: " ..
                            "нужно %d ед. дерева или камня на карте.",
                            MATERIALS_PER_LADDER))
                    end,
                }
                QuestsField:ShowContextMenu(menuItems, btn)
                return true
            end

            -- 3.3. По пункту на материал
            for _, m in ipairs(materials) do
                local mid    = m.id
                local mlabel = m.label
                menuItems[#menuItems + 1] = {
                    text = string.format("Постройка лестницы: %s (есть %d)",
                        mlabel, m.count),
                    func = function()
                        local Terrain = NSQC4.QuestsDfTerrain
                        if not (Terrain and Terrain.SetTerrain) then return end

                        -- ставим лестницу
                        Terrain:SetTerrain(idx, "ladder")

                        -- 1 HP и регистрация в таблице строек с материалом
                        if Grid then
                            Grid:SetHardness(idx, 1)
                            if Grid.AddBuilding then
                                Grid:AddBuilding(idx, "ladder", 1000, mid)
                            end
                        end

                        -- перерисовать клетку (RenderCellFromStorage увидит
                        -- IsBuilding, поставит alpha=0.5, tint по материалу)
                        if NSQC4.QuestsDfTerrainUIApi
                           and NSQC4.QuestsDfTerrainUIApi.RenderCellFromStorage then
                            NSQC4.QuestsDfTerrainUIApi:RenderCellFromStorage(idx)
                        end

                        print(string.format(
                            "|cff00ff00[NSQC4]|r Лестница в постройке (%s, 1/1000) в клетке %d",
                            mlabel, idx))
                    end,
                }
            end

            QuestsField:ShowContextMenu(menuItems, btn)
            return true
        end)

        return true
    end

end)