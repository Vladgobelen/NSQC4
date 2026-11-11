-- ============================================================================
-- NSQC4 / Quests / Field / Cells / Reflow
-- Одна логика: раскладка 20 линий сетки.
--
--   cellW = (fw - PAD*2 - (COLS-1)*GAP) / COLS
--   cellH = (fh - PAD*2 - (ROWS-1)*GAP) / ROWS
--
--   Вертикальная линия i (1..COLS+1) — на границе i-й колонки.
--   Горизонтальная линия j (1..ROWS+1) — на границе j-й строки.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    local CONST       = NSQC4.QuestsFieldConst
    if not QuestsField or not CONST then return end

    local COLS, ROWS   = CONST.COLS, CONST.ROWS
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

        -- Вертикальные
        for i = 1, COLS + 1 do
            local tex = lines.v[i]
            local x = GRID_PADDING + (i - 1) * (cellW + CELL_GAP)
            tex:ClearAllPoints()
            tex:SetPoint("TOPLEFT",     f, "BOTTOMLEFT", x, GRID_PADDING + gridH)
            tex:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT", x, GRID_PADDING)
            tex:SetWidth(1)
            tex:Show()
        end

        -- Горизонтальные
        for j = 1, ROWS + 1 do
            local tex = lines.h[j]
            local y = GRID_PADDING + (j - 1) * (cellH + CELL_GAP)
            tex:ClearAllPoints()
            tex:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT", GRID_PADDING,            y)
            tex:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", GRID_PADDING + gridW,    y)
            tex:SetHeight(1)
            tex:Show()
        end
    end

end, 330)