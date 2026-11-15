-- ============================================================================
-- NSQC4 / Quests / Field / Cells / Reflow / Vertical
-- Одна логика: раскладка вертикальных линий сетки.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    local CONST       = NSQC4.QuestsFieldConst
    if not QuestsField or not CONST then return end

    local COLS         = CONST.COLS
    local CELL_GAP     = CONST.CELL_GAP
    local GRID_PADDING = CONST.GRID_PADDING

    function QuestsField:ReflowVerticalLines(f, cellW, gridH)
        local lines = self.gridLines
        if not lines or not lines.v then return end

        for i = 1, COLS + 1 do
            local tex = lines.v[i]
            if tex then
                local x = GRID_PADDING + (i - 1) * (cellW + CELL_GAP)
                tex:ClearAllPoints()
                tex:SetPoint("TOPLEFT",     f, "BOTTOMLEFT", x, GRID_PADDING + gridH)
                tex:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT", x, GRID_PADDING)
                tex:SetWidth(1)
                tex:Show()
            end
        end
    end

end, 331)