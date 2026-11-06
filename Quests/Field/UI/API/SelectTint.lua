-- ============================================================================
-- NSQC4 / Quests / Field / UI / API / SelectTint
-- API поля: «выделение клетки с оттенком».
--
-- Поле НЕ знает про типы ландшафта. Оно умеет только «покрасить выделенную
-- клетку в оттенок X». Какой оттенок — решает df-объект
-- (df/Actions/Terrain/<Type>/LeftClickSelf.lua), потому что он знает свой
-- цвет.
--
-- Хранение: btn._crSelectTint = { r, g, b, a } | nil
-- Применение: при перерисовке клетки CellRender берёт btn._crSelectTint
--             в приоритете над TerrainUIApi:ResolveHighlight (fallback).
--
-- Снятие: при Grid:SetTerrainSelected(..., false) поле снимает тинт само
--         (см. Grid.lua). df зовёт SetCellSelectTint только при выделении.
--
-- API:
--   QuestsField:SetCellSelectTint(index, r, g, b, a)   -- nil → снять
--   QuestsField:ClearCellSelectTint(index)
--   QuestsField:GetCellSelectTint(index)               -- { r,g,b,a } | nil
--
-- Перерисовка — через TerrainUIApi:RenderCellFromStorage (как у остальных
-- мутаторов поля), потому что это перечитывает данные Grid, а не накладывает
-- заплатку поверх старого spec.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then
        print("|cffff0000[NSQC4]|r SelectTint: ядро поля не загружено.")
        return
    end

    local CONST = NSQC4.QuestsFieldConst
    local TOTAL = CONST and (CONST.COLS * CONST.ROWS) or 100

    local function Valid(index)
        index = tonumber(index) or 0
        return (index >= 1 and index <= TOTAL) and index or nil
    end

    local function Redraw(index)
        local TerrainApi = NSQC4.QuestsDfTerrainUIApi
        if TerrainApi and TerrainApi.RenderCellFromStorage then
            TerrainApi:RenderCellFromStorage(index)
            return true
        end
        return false
    end

    -- ========================================================================
    -- Пометить клетку как «выбранную» с оттенком.
    --   index   — 1..100
    --   r,g,b,a — оттенок (r == nil → снять, эквивалент ClearCellSelectTint)
    -- ========================================================================
    function QuestsField:SetCellSelectTint(index, r, g, b, a)
        index = Valid(index)
        if not index then return false end

        local btn = self.cells and self.cells[index]
        if not btn then return false end

        if r == nil then
            btn._crSelectTint = nil
        else
            btn._crSelectTint = { r, g or r, b or r, a or 1 }
        end

        Redraw(index)
        return true
    end

    -- ========================================================================
    -- Снять оттенок выделения (клетка остаётся «выбранной» по данным Grid).
    -- ========================================================================
    function QuestsField:ClearCellSelectTint(index)
        return self:SetCellSelectTint(index, nil)
    end

    -- ========================================================================
    -- Узнать текущий оттенок (для диагностики / fallback-логики).
    -- ========================================================================
    function QuestsField:GetCellSelectTint(index)
        index = Valid(index)
        if not index then return nil end
        local btn = self.cells and self.cells[index]
        return btn and btn._crSelectTint or nil
    end

    print("|cff00ffff[SELTINT]|r SelectTint API загружен (SetCellSelectTint / ClearCellSelectTint / GetCellSelectTint).")

end)