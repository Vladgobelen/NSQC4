-- ============================================================================
-- NSQC4 / Quests / Field / Cells / Reflow / Refresh
-- Одна логика: оркестрация раскладки сетки (вертикальные + горизонтальные).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    local CONST       = NSQC4.QuestsFieldConst
    if not QuestsField or not CONST then return end

    local COLS         = CONST.COLS
    local ROWS         = CONST.ROWS
    local CELL_GAP     = CONST.CELL_GAP
    local GRID_PADDING = CONST.GRID_PADDING

    function QuestsField:ReflowCells()
        local f = self.frame
        if not f then return end

        local lines = self.gridLines
        if not lines then return end

        local fw, fh = f:GetWidth(), f:GetHeight()

        local cellW = (fw - GRID_PADDING * 2 - (COLS - 1) * CELL_GAP) / COLS
        local cellH = (fh - GRID_PADDING * 2 - (ROWS - 1) * CELL_GAP) / ROWS

        local gridW = fw - GRID_PADDING * 2
        local gridH = fh - GRID_PADDING * 2

        -- Вызов вертикалей и горизонталей
        self:ReflowVerticalLines(f, cellW, gridH)
        self:ReflowHorizontalLines(f, cellH, gridW)
    end

end, 333)