-- ============================================================================
-- NSQC4 / Quests / Field / Resize / Apply
-- Одна логика: вычислить cellSize по позиции мыши и применить.
--
--   QuestsField:ApplyResize(cursorX, cursorY, anchorL, anchorT) → true | false
--
--   anchorL, anchorT — координаты левого-верхнего угла frame в момент
--     OnMouseDown (запоминает Handle.lua).
--   cursorX, cursorY — текущая позиция мыши (в координатах UIParent).
--
--   rawW = cursorX - anchorL
--   rawH = anchorT - cursorY
--   csX  = (rawW - (COLS-1)*GAP - 2*PAD) / COLS
--   csY  = (rawH - (ROWS-1)*GAP - 2*PAD) / ROWS
--   cs   = max(csX, csY)  (по большей стороне — тянем пропорционально)
--   → Resize(cs)
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    local CONST       = NSQC4.QuestsFieldConst
    if not QuestsField or not CONST then return end

    local COLS, ROWS   = CONST.COLS, CONST.ROWS
    local CELL_GAP     = CONST.CELL_GAP
    local GRID_PADDING = CONST.GRID_PADDING

    function QuestsField:ApplyResize(cursorX, cursorY, anchorL, anchorT)
        if not cursorX or not cursorY or not anchorL or not anchorT then
            return false
        end

        local rawW = cursorX - anchorL
        local rawH = anchorT - cursorY

        local csX = (rawW - (COLS - 1) * CELL_GAP - GRID_PADDING * 2) / COLS
        local csY = (rawH - (ROWS - 1) * CELL_GAP - GRID_PADDING * 2) / ROWS
        local cs  = math.max(csX, csY)

        return self:Resize(cs)
    end

end, 410)