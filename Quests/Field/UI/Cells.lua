-- ============================================================================
-- NSQC4 / Quests / Field / UI / Cells
-- Создание сетки кнопок и раскладка. Клики не вешает — это Highlight.
--
-- BORDERLESS:
--   При создании клетки рамка (SetBackdropBorderColor) ставится
--   в зависимости от QuestsField:IsBorderless():
--     - false (nil) → 0.25, 0.25, 0.25, 1  (рамка есть)
--     - true  (1)   → 0,    0,    0,    0  (рамки нет)
--
--   И в ReflowCells учитывается gap:
--     - borderless = nil → CELL_GAP (0) — клетки вплотную (визуально
--       разделены 1 px рамкой)
--     - borderless = 1   → gap = -1 — клетки перекрываются на 1 px,
--       чтобы не было даже минимального визуального зазора (рамки нет,
--       перекрытие «склеивает» клетки)
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

    -- ========================================================================
    -- Актуальный gap: CELL_GAP (0) по умолчанию,
    -- при borderless — -1 (клетки перекрываются на 1 px).
    -- ========================================================================
    local function EffectiveGap(self)
        if self:IsBorderless() then return -1 end
        return CELL_GAP
    end

    function QuestsField:ReflowCells()
        local f = self.frame
        if not f then return end
        local fw, fh = f:GetWidth(), f:GetHeight()
        local gap = EffectiveGap(self)

        local cellW = (fw - GRID_PADDING * 2 - (COLS - 1) * gap) / COLS
        local cellH = (fh - GRID_PADDING * 2 - (ROWS - 1) * gap) / ROWS

        for index, btn in pairs(self.cells) do
            local col, row = IndexToColRow(index)
            btn:ClearAllPoints()
            btn:SetSize(cellW, cellH)
            btn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT",
                GRID_PADDING + col * (cellW + gap),
                GRID_PADDING + row * (cellH + gap))
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

        -- рамка: по умолчанию 0.25 (есть), если borderless — 0 (нет)
        if self:IsBorderless() then
            btn:SetBackdropBorderColor(0, 0, 0, 0)
        else
            btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
        end

        return btn
    end
end)