-- ============================================================================
-- NSQC4 / Quests / Field / UI / API / Clear
-- Полная очистка визуала клетки и всего поля.
--
-- ВСЁ рисование теперь в CellRender.lua. ClearCell:
--   1. зовёт ClearCellRender(index) — снимает bg/terrain/build/loot/anchor/temp;
--   2. сбрасывает btn._crSpec / btn._crLastEntity — чтобы следующая обёртка
--      SetCellTexture/SetCellBuild не «дополняла» старый spec;
--   3. снимает тултип/клики/ховер-состояние (_tooltipFn/_onEnter/_onLeave/
--      _lastStateKey/_hoverInitialized);
--   4. рамку кнопки — по IsBorderless().
--
-- Поля btn.texture / btn.build / btn.hoverTexture / btn.anchors /
-- btn._lootTextures / btn._lootBorders БОЛЬШЕ НЕ СУЩЕСТВУЮТ как отдельные
-- источники правды — их заменяет btn._cr (см. CellRender.lua).
-- Если где-то в старом коде на них ещё ссылаются — это надо убрать
-- (см. шаги 5–7 миграции).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    local CONST       = NSQC4.QuestsFieldConst
    if not QuestsField or not CONST then return end

    local COLS, ROWS = CONST.COLS, CONST.ROWS
    local TOTAL = COLS * ROWS

    -- ========================================================================
    -- Очистка одной клетки
    -- ========================================================================
    function QuestsField:ClearCell(index)
        self:EnsureFrame()
        local btn = self.cells and self.cells[index]
        if not btn then return end

        -- 1. Снять весь рендер (bg/terrain/build/loot/anchor/temp) через CellRender
        if self.ClearCellRender then
            self:ClearCellRender(index)
        end

        -- 2. Сбросить накопленный spec и последний entity-spec
        btn._crSpec        = nil
        btn._crLastEntity  = nil

        -- 3. Снять тултип/клики/ховер (как раньше)
        btn._onEnter          = nil
        btn._onLeave          = nil
        btn._tooltipFn        = nil
        btn._lastStateKey     = nil
        btn._hoverInitialized = nil
        btn._hovered          = false
        btn._mouseHandlers    = nil
        btn:SetScript("OnClick", nil)
        btn:RegisterForClicks()
        btn:SetScript("OnEnter", nil)
        btn:SetScript("OnLeave", nil)

        -- 4. Рамка кнопки — по IsBorderless()
        if self:IsBorderless() then
            btn:SetBackdropBorderColor(0, 0, 0, 0)
        else
            btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
        end
    end

    -- ========================================================================
    -- Очистка всего поля
    -- ========================================================================
    function QuestsField:ClearAll()
        for i = 1, TOTAL do
            self:ClearCell(i)
        end
    end

end)