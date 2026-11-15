-- ============================================================================
-- NSQC4 / Quests / Field / Cells / Reflow / Horizontal
-- Одна логика: раскладка горизонтальных линий сетки.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    local CONST       = NSQC4.QuestsFieldConst
    if not QuestsField or not CONST then return end

    local ROWS         = CONST.ROWS
    local CELL_GAP     = CONST.CELL_GAP
    local GRID_PADDING = CONST.GRID_PADDING

    function QuestsField:ReflowHorizontalLines(f, cellH, gridW)
        local lines = self.gridLines
        if not lines or not lines.h then return end

        for j = 1, ROWS + 1 do
            local tex = lines.h[j]
            if tex then
                local y = GRID_PADDING + (j - 1) * (cellH + CELL_GAP)
                tex:ClearAllPoints()
                tex:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT", GRID_PADDING,         y)
                tex:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", GRID_PADDING + gridW, y)
                tex:SetHeight(1)
                tex:Show()
            end
        end
    end

end, 332)