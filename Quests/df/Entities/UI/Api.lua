-- ============================================================================
-- NSQC4 / Quests / df / Entities / UI / Api
-- Визуал существ: ТОЛЬКО иконка. Клики и тултип НЕ вешает.
--
-- Клики существа вешает ландшафт (TerrainActions) через Mouse.
-- Тултип существа вешает TerrainUIApi (владелец клетки) через
-- QuestsField:SetCellTooltip / ClearCellTooltip (Field/UI/API/Tooltip.lua).
--
-- Пока идёт анимация (Animate:IsAnimating(id)), Render пропускается —
-- иконку ведёт Animate, а не Api. Иначе телепорт перебьёт анимацию.
--
-- Контракт opts:
--   icon    = "path"            — иконка (обязательна для Render)
--   anchor  = "TOPLEFT"|...     — позиция (по умолчанию "TOPLEFT")
--   expanded= true|false        — на всю клетку / 1/3
--   alpha   = 0..1              — прозрачность иконки
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsField
    if not QuestsField then
        print("|cffff0000[NSQC4]|r Entities/UI/Api: ядро поля не загружено.")
        return
    end

    local CONST = NSQC4.QuestsFieldConst
    if not CONST then return end
    local TOTAL = CONST.COLS * CONST.ROWS

    -- ========================================================================
    -- Namespace API
    -- ========================================================================
    local UIApi = {}
    NSQC4.QuestsDfEntitiesUIApi = UIApi

    -- ========================================================================
    -- Константы
    -- ========================================================================
    local DEFAULT_ANCHOR = "TOPLEFT"
    local DEFAULT_ALPHA  = 1.0

    local function Valid(index)
        index = tonumber(index) or 0
        return (index >= 1 and index <= TOTAL) and index or nil
    end

    -- ========================================================================
    -- Идёт ли анимация у существа в клетке index?
    -- Смотрим entity в Grid: если у него есть id и Animate:IsAnimating(id)
    -- → true. Тогда Render не трогает иконку.
    -- ========================================================================
    local function IsAnimatingAt(index)
        local Animate = NSQC4.QuestsDfEntitiesAnimate
        if not Animate or not Animate.IsAnimating then return false end

        local Grid = NSQC4.QuestsDfGrid
        if not Grid then return false end

        local entity = Grid:GetEntity(index)
        if not entity or not entity.id then return false end

        return Animate:IsAnimating(entity.id)
    end

    -- ========================================================================
    -- RENDER — ТОЛЬКО визуал иконки существа в клетке.
    --   opts == nil → очистить иконку (якоря).
    --   Клики и тултип НЕ трогает.
    --   Если идёт анимация — ничего не делает (иконку ведёт Animate).
    -- ========================================================================
    function UIApi:Render(index, opts)
        index = Valid(index)
        if not index then return false end

        -- Анимация в приоритете: не трогаем иконку
        if IsAnimatingAt(index) then
            return true
        end

        if not opts then
            QuestsField:ClearAnchorTextures(index)
            return true
        end

        local anchor   = opts.anchor   or DEFAULT_ANCHOR
        local expanded = opts.expanded and true or false
        local alpha    = opts.alpha    or DEFAULT_ALPHA

        if opts.icon then
            QuestsField:SetAnchorExpanded(index, anchor, opts.icon, expanded)
            local cell = QuestsField.cells and QuestsField.cells[index]
            local tex  = cell and cell.anchors and cell.anchors[anchor]
            if tex then tex:SetAlpha(alpha) end
        else
            QuestsField:ClearAnchorTextures(index)
        end

        return true
    end

    -- ========================================================================
    -- RENDER CELL FROM STORAGE — иконка по данным из Grid:GetEntity(index)
    -- ========================================================================
    function UIApi:RenderCellFromStorage(index)
        index = Valid(index)
        if not index then return false end

        local Grid = NSQC4.QuestsDfGrid
        if not Grid then return false end

        local entity = Grid:GetEntity(index)
        if not entity or not entity.opts then
            self:Render(index, nil)
            return true
        end

        local opts = entity.opts

        self:Render(index, {
            icon     = opts.icon or opts.texture,
            anchor   = opts.anchor,
            expanded = opts.expanded,
            alpha    = opts.alpha,
        })

        return true
    end

    -- ========================================================================
    -- RENDER ALL
    -- ========================================================================
    function UIApi:RenderAll()
        for i = 1, TOTAL do
            self:RenderCellFromStorage(i)
        end
    end

end)