-- ============================================================================
-- NSQC4 / Quests / df / Actions / Terrain / Ladder / LeftClickSelf
-- ЛКМ по ladder:
--   1. Активное существо → LeftClickEntities (развернуть/свернуть).
--   2. Лут → не выделяем.
--   3. Toggle выделения. Сообщение — по hp/max:
--        hp >= max → готова
--        hp <  max → задача на постройку
--
-- ВЫДЕЛЕНИЕ С ОТТЕНКОМ:
--   Цвет задаёт сам объект (SELECT_TINT). Для лестницы — по материалу
--   постройки (wood/stone/metal/gold), по умолчанию — коричневый (дерево).
--   Поле только красит (QuestsField:SetCellSelectTint). При де-выделении
--   поле снимает тинт само (Grid:SetTerrainSelected(..., false)).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local A = NSQC4.QuestsDfTerrainActions
    if not A then
        print("|cffff0000[NSQC4]|r Ladder/LeftClickSelf: Init.lua не загружен.")
        return
    end

    local QuestsField = NSQC4.QuestsField
    if not QuestsField then return end

    local Grid = NSQC4.QuestsDfGrid

    -- Цвета выделения ladder — по материалу постройки.
    local SELECT_TINT_BY_MATERIAL = {
        wood  = { 0.55, 0.35, 0.20, 1.0 },
        stone = { 0.60, 0.60, 0.60, 1.0 },
        metal = { 0.80, 0.80, 0.90, 1.0 },
        gold  = { 1.00, 0.85, 0.10, 1.0 },
    }
    local SELECT_TINT_DEFAULT = SELECT_TINT_BY_MATERIAL.wood

    local function ResolveLadderTint(idx)
        -- ВАЖНО: Grid.GetBuilding (точка) для проверки, Grid:GetBuilding
        -- (двоеточие) для вызова. Иначе Lua видит Grid:GetBuilding как
        -- вызов метода без аргументов и падает «function arguments expected».
        local b = Grid and Grid.GetBuilding and Grid:GetBuilding(idx)
        local material = b and b.material or "wood"
        return SELECT_TINT_BY_MATERIAL[material] or SELECT_TINT_DEFAULT
    end

    A.Types["ladder"] = A.Types["ladder"] or {}

    A.Types["ladder"].LeftClickSelf = function(index)
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
                          and NSQC4.QuestsDfTerrainActions.Types["ladder"]
                if T and T.LeftClickEntities then
                    return T.LeftClickEntities(idx)
                end
                return false
            end

            -- 2. Лут блокирует выделение
            local hasLoot = Drops and Drops:HasAny(idx) or false
            if hasLoot then return false end

            -- 3. Toggle выделения + сообщение по hp/max
            if not Grid then return false end

            local isSelected = Grid:IsTerrainSelected(idx)

            if isSelected then
                Grid:SetTerrainSelected(idx, "ladder", false)
                print("|cffff8800[NSQC4]|r Снято выделение ladder в клетке " .. idx ..
                      " — не трогают.")
            else
                Grid:SetTerrainSelected(idx, "ladder", true)
                local tint = ResolveLadderTint(idx)
                QuestsField:SetCellSelectTint(idx,
                    tint[1], tint[2], tint[3], tint[4])

                local b   = Grid:GetBuilding(idx)
                local hp  = b and tonumber(b.hp)  or 0
                local max = b and tonumber(b.max) or 1000

                if hp >= max then
                    print("|cff00ff00[NSQC4]|r Выделено ladder в клетке " .. idx ..
                          " — готова (спуск/подъём).")
                else
                    print("|cff00ff00[NSQC4]|r Выделено ladder в клетке " .. idx ..
                          " — задача на ПОСТРОЙКУ (hp < max).")
                end
            end

            return true
        end)

        return true
    end

end)