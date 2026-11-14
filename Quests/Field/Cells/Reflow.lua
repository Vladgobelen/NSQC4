-- ============================================================================
-- NSQC4 / Quests / Field / Cells / Reflow
-- Одна логика: раскладка 20 линий сетки.
--
-- ОТЛАДКА: [REFLOW]. Отключить — REFLOW_DEBUG = false.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    local CONST       = NSQC4.QuestsFieldConst
    if not QuestsField or not CONST then return end

    local REFLOW_DEBUG = true
    local function dbg(...)
        if REFLOW_DEBUG then print("|cffffaa00[REFLOW]|r", ...) end
    end

    local COLS, ROWS   = CONST.COLS, CONST.ROWS
    local CELL_GAP     = CONST.CELL_GAP
    local GRID_PADDING = CONST.GRID_PADDING

    function QuestsField:ReflowCells()
        local f = self.frame
        if not f then
            dbg("frame == nil — выход")
            return
        end

        local lines = self.gridLines
        if not lines then
            dbg("gridLines == nil — CreateCells не вызван?")
            return
        end

        local fw, fh = f:GetWidth(), f:GetHeight()
        dbg(string.format("frame w=%d h=%d, COLS=%d ROWS=%d PAD=%d GAP=%d",
            fw, fh, COLS, ROWS, GRID_PADDING, CELL_GAP))

        local cellW = (fw - GRID_PADDING * 2 - (COLS - 1) * CELL_GAP) / COLS
        local cellH = (fh - GRID_PADDING * 2 - (ROWS - 1) * CELL_GAP) / ROWS
        local gridW = fw - GRID_PADDING * 2
        local gridH = fh - GRID_PADDING * 2
        dbg(string.format("cellW=%.1f cellH=%.1f gridW=%.1f gridH=%.1f",
            cellW, cellH, gridW, gridH))

        local vCount, hCount = 0, 0

        -- Вертикальные
        for i = 1, COLS + 1 do
            local tex = lines.v[i]
            if tex then
                local x = GRID_PADDING + (i - 1) * (cellW + CELL_GAP)
                tex:ClearAllPoints()
                tex:SetPoint("TOPLEFT",    f, "BOTTOMLEFT", x, GRID_PADDING + gridH)
                tex:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", x, GRID_PADDING)
                tex:SetWidth(1)
                tex:Show()
                vCount = vCount + 1
            else
                dbg("lines.v[" .. i .. "] == nil")
            end
        end

        -- Горизонтальные
        for j = 1, ROWS + 1 do
            local tex = lines.h[j]
            if tex then
                local y = GRID_PADDING + (j - 1) * (cellH + CELL_GAP)
                tex:ClearAllPoints()
                tex:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT", GRID_PADDING,         y)
                tex:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", GRID_PADDING + gridW, y)
                tex:SetHeight(1)
                tex:Show()
                hCount = hCount + 1
            else
                dbg("lines.h[" .. j .. "] == nil")
            end
        end

        dbg(string.format("разложено: v=%d h=%d (ожидалось v=%d h=%d)",
            vCount, hCount, COLS + 1, ROWS + 1))
    end

end, 330)