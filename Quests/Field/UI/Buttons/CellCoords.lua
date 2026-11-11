-- ============================================================================
-- NSQC4 / Quests / Field / UI / Buttons / CellCoords
-- Одна логика: геометрия. CellCenterXY / PanelButtonXY.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    local CONST       = NSQC4.QuestsFieldConst
    if not QuestsField or not CONST then return end

    local COLS, ROWS   = CONST.COLS, CONST.ROWS
    local CELL_GAP     = CONST.CELL_GAP
    local GRID_PADDING = CONST.GRID_PADDING

    function QuestsField:CellCenterXY(index)
        local f = self.frame
        if not f then return nil end
        local fw, fh = f:GetWidth(), f:GetHeight()

        local i = (tonumber(index) or 0) - 1
        local col = i % COLS
        local row = math.floor(i / COLS)

        local cellW = (fw - GRID_PADDING * 2 - (COLS - 1) * CELL_GAP) / COLS
        local cellH = (fh - GRID_PADDING * 2 - (ROWS - 1) * CELL_GAP) / ROWS

        local cx = GRID_PADDING + col * (cellW + CELL_GAP) + cellW / 2
        local cy = GRID_PADDING + row * (cellH + CELL_GAP) + cellH / 2
        return cx, cy
    end

    function QuestsField:PanelButtonXY(side, index)
        local f = self.frame
        if not f then return nil end
        local fw, fh = f:GetWidth(), f:GetHeight()
        local cx, cy = self:CellCenterXY(index)
        if not cx then return nil end

        local half = GRID_PADDING / 2

        if side == "RIGHT" then
            return fw - half, cy
        elseif side == "LEFT" then
            return half, cy
        elseif side == "TOP" then
            return cx, fh - half
        elseif side == "BOTTOM" then
            return cx, half
        end
        return nil
    end

end, 440)