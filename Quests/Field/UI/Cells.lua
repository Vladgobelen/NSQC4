-- ============================================================================
-- NSQC4 / Quests / Field / UI / Cells
-- Создание сетки кнопок и раскладка. Клики не вешает — это Highlight.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local QuestsField = NSQC4.QuestsFieldClass
    local CONST       = NSQC4.QuestsFieldConst
    if not QuestsField or not CONST then return end

    local COLS, ROWS   = CONST.COLS, CONST.ROWS
    local CELL_GAP     = CONST.CELL_GAP
    local GRID_PADDING = CONST.GRID_PADDING

    local function IndexToColRow(index)
        local i = index - 1
        return i % COLS, math.floor(i / COLS)
    end

    function QuestsField:ReflowCells()
        local f = self.frame
        if not f then return end
        local fw, fh = f:GetWidth(), f:GetHeight()
        local cellW = (fw - GRID_PADDING * 2 - (COLS - 1) * CELL_GAP) / COLS
        local cellH = (fh - GRID_PADDING * 2 - (ROWS - 1) * CELL_GAP) / ROWS
        for index, btn in pairs(self.cells) do
            local col, row = IndexToColRow(index)
            btn:ClearAllPoints()
            btn:SetSize(cellW, cellH)
            btn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT",
                GRID_PADDING + col * (cellW + CELL_GAP),
                GRID_PADDING + row * (cellH + CELL_GAP))
        end
    end

    function QuestsField:CreateCell(index)
        local f = self.frame
        local btn = CreateFrame("Button", "NSQC4FieldCell" .. index, f)

        btn:SetFrameLevel(f:GetFrameLevel() + 10)

        btn:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(0, 0, 0, 0)
        btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)

        return btn
    end
end)