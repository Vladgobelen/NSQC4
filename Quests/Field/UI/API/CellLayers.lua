-- ============================================================================
-- NSQC4 / Quests / Field / UI / API / CellLayers
-- API поля: «положить/снять ОДИН слой клетки, не собирая весь spec».
--
-- Зачем: df-слой (Drops, EntitiesUIApi) раньше сам лез в btn._crSpec и
-- мержил туда свой слой:
--     local spec = btn._crSpec or {}
--     spec.loot = self:BuildLootSpec(index)
--     return QuestsField:RenderCell(index, spec)
-- Это знание внутренностей CellRender в df. Теперь df отдаёт ТОЛЬКО свой
-- слой, а мерж и перерисовку делает поле.
--
-- Слои, которые можно класть отдельно:
--   spec.loot   — массив { { anchor, texture, border }, ... } | nil
--   spec.entity — { anchor, expanded, texture, alpha, moving, posX, posY } | nil
--
-- Остальные слои (bg/terrain/build/highlight/text) не трогаются — они уже
-- лежат в btn._crSpec от последнего RenderCellFromStorage.
--
-- API:
--   QuestsField:SetCellLootSpec(index, lootSpec)      -- nil → снять лут
--   QuestsField:SetCellEntitySpec(index, entitySpec)  -- nil → снять entity
--
-- Оба метода:
--   1. берут btn._crSpec (или {})
--   2. заменяют ОДИН слой
--   3. зовут RenderCell (он сохранит _crSpec обратно)
--   4. для entity — обновляют btn._crLastEntity (его читает RefreshCellSize)
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then
        print("|cffff0000[NSQC4]|r CellLayers: ядро поля не загружено.")
        return
    end

    if not QuestsField.RenderCell then
        print("|cffff0000[NSQC4]|r CellLayers: RenderCell не найден (CellRender.lua не загружен?).")
        return
    end

    local CONST = NSQC4.QuestsFieldConst
    local TOTAL = CONST and (CONST.COLS * CONST.ROWS) or 100

    local function Valid(index)
        index = tonumber(index) or 0
        return (index >= 1 and index <= TOTAL) and index or nil
    end

    -- ========================================================================
    -- ЛУТ
    --   lootSpec — массив { { anchor, texture, border=true }, ... } | nil
    --              nil или пустой массив → лут снимается (spec.loot = nil)
    -- ========================================================================
    function QuestsField:SetCellLootSpec(index, lootSpec)
        index = Valid(index)
        if not index then return false end

        local btn = self.cells and self.cells[index]
        if not btn then return false end

        local spec = btn._crSpec or {}

        if type(lootSpec) == "table" and #lootSpec > 0 then
            spec.loot = lootSpec
        else
            spec.loot = nil
        end

        return self:RenderCell(index, spec)
    end

    -- ========================================================================
    -- СУЩЕСТВО
    --   entitySpec — { anchor, expanded, texture, alpha, moving, posX, posY } | nil
    --                nil → entity снимается (spec.entity = nil)
    -- ========================================================================
    function QuestsField:SetCellEntitySpec(index, entitySpec)
        index = Valid(index)
        if not index then return false end

        local btn = self.cells and self.cells[index]
        if not btn then return false end

        local spec = btn._crSpec or {}
        spec.entity = entitySpec

        btn._crLastEntity = entitySpec
        return self:RenderCell(index, spec)
    end

    print("|cff00ffff[CELLLAYERS]|r CellLayers API загружен (SetCellLootSpec / SetCellEntitySpec).")

end)