-- ============================================================================
-- NSQC4 / Quests / Field / Frame / Create
-- Одна логика: создание главного frame поля.
--
-- Читает: QuestsFieldConst, self.saved.
-- Пишет:  self.frame, self.cellSize.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    local CONST       = NSQC4.QuestsFieldConst
    if not QuestsField or not CONST then return end

    local COLS, ROWS     = CONST.COLS, CONST.ROWS
    local CELL_GAP       = CONST.CELL_GAP
    local GRID_PADDING   = CONST.GRID_PADDING
    local DEFAULT_CELL   = CONST.DEFAULT_CELL
    local MIN_CELL       = CONST.MIN_CELL
    local MAX_CELL       = CONST.MAX_CELL
    local SCREEN_PERCENT = CONST.SCREEN_PERCENT or 0.9

    -- ========================================================================
    -- FrameSizeForCell — размер frame по cellSize. Чистая функция.
    -- ========================================================================
    local function FrameSizeForCell(cs)
        return cs * COLS + (COLS - 1) * CELL_GAP + GRID_PADDING * 2,
               cs * ROWS + (ROWS - 1) * CELL_GAP + GRID_PADDING * 2
    end
    QuestsField._FrameSizeForCell = FrameSizeForCell

    -- ========================================================================
    -- MaxCellForScreen — предел cellSize по экрану (90% узкой стороны).
    -- ========================================================================
    function QuestsField:MaxCellForScreen()
        local uiW = (UIParent and UIParent:GetWidth())  or 0
        local uiH = (UIParent and UIParent:GetHeight()) or 0
        local minSide = math.min(uiW, uiH)
        if minSide <= 0 then return MAX_CELL end

        local maxSide = minSide * SCREEN_PERCENT
        local byW = (maxSide - (COLS - 1) * CELL_GAP) / COLS
        local byH = (maxSide - (ROWS - 1) * CELL_GAP) / ROWS
        local maxFromScreen = math.floor(math.min(byW, byH))

        if maxFromScreen < MIN_CELL then maxFromScreen = MIN_CELL end
        return math.min(MAX_CELL, maxFromScreen)
    end

    -- ========================================================================
    -- CreateFrame
    -- ========================================================================
    function QuestsField:CreateFrame()
        if self.frame then return self.frame end

        if not self.saved then self:Load() end
        local saved = self.saved or {}

        local effMaxCell = self:MaxCellForScreen()

        local cs = math.floor((saved.cellSize or DEFAULT_CELL) + 0.5)
        if cs < MIN_CELL then cs = MIN_CELL end
        if cs > effMaxCell then cs = effMaxCell end

        self.cellSize = cs

        local w0, h0 = FrameSizeForCell(cs)

        local f = CreateFrame("Frame", "NSQC4FieldFrame", UIParent)
        self.frame = f
        f:SetFrameStrata("MEDIUM")
        f:SetMovable(true)
        f:SetClampedToScreen(false)
        f:SetSize(w0, h0)

        f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        f:SetBackdropColor(0, 0, 0, 0.35)
        f:EnableMouse(false)

        if saved.x and saved.y then
            f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", saved.x, saved.y)
        else
            f:SetPoint("CENTER")
        end

        f:Hide()
        return f
    end

end, 300)