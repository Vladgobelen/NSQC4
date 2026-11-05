-- ============================================================================
-- NSQC4 / Quests / Field / UI / Frame
-- Создание главного фрейма поля + клетки + рамка + ресайз + крестик.
-- Клики по клеткам НЕ вешает — это делают модули (TerrainActions → Mouse).
-- Здесь только: drag фрейма, ресайз, крестик, раскладка.
--
-- РЕЖИМЫ ОТОБРАЖЕНИЯ (self.viewMode):
--   "detail"   — обычный вид: 10×10 детальных клеток.
--   "overview" — вид сверху: 10×10 «больших» квадратов, наш этаж — 1 из 100,
--                внутри — 10×10 пикселей (см. Overview.lua).
--
-- Show():
--   - если viewMode == "overview" → self:ShowOverview() (а не детальный рендер)
--   - иначе                       → детальный рендер (Terrain/Entities)
-- Hide():
--   - скрыть overview (если был), скрыть тултип, скрыть frame
-- Toggle():
--   - просто Show/Hide, режим сохраняется
--
-- OnSizeChanged:
--   - ReflowCells + ApplyBorderAnchors (как раньше)
--   - если viewMode == "overview" → self:RefreshOverviewLayout() (если Overview
--     загружен; метод экспортируется из Overview.lua)
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

    local function FrameSizeForCell(cs)
        return cs * COLS + (COLS - 1) * CELL_GAP + GRID_PADDING * 2,
               cs * ROWS + (ROWS - 1) * CELL_GAP + GRID_PADDING * 2
    end
    QuestsField._FrameSizeForCell = FrameSizeForCell

    -- ========================================================================
    -- EnsureFrame — создать фрейм и всё вокруг (идемпотентно)
    -- ========================================================================
    function QuestsField:EnsureFrame()
        if self.frame then return self.frame end

        if not self.saved then self:Load() end
        local saved = self.saved or {}

        local cs = math.floor((saved.cellSize or DEFAULT_CELL) + 0.5)
        if cs < MIN_CELL then cs = MIN_CELL end
        if cs > MAX_CELL then cs = MAX_CELL end
        self.cellSize = cs

        local w0, h0 = FrameSizeForCell(cs)

        local f = CreateFrame("Frame", "NSQC4FieldFrame", UIParent)
        self.frame = f
        f:SetFrameStrata("MEDIUM")
        f:SetMovable(true)
        f:SetClampedToScreen(true)
        f:SetSize(w0, h0)
        f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        f:SetBackdropColor(0, 0, 0, 0)
        f:EnableMouse(false)

        if saved.x and saved.y then
            f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", saved.x, saved.y)
        else
            f:SetPoint("CENTER")
        end

        -- Клетки
        for index = 1, COLS * ROWS do
            self.cells[index] = self:CreateCell(index)
        end
        self:ReflowCells()

        -- UI-механика фрейма (не клики клеток)
        self:CreateBorder()
        self:CreateResizeHandle()
        self:CreateCloseButton()

        if saved.borderVisible then
            self.borderVisible = false
            self:SetBorderVisible(true)
        end

        -- OnSizeChanged: ReflowCells + ApplyBorderAnchors + Overview layout
        f:HookScript("OnSizeChanged", function()
            self:ReflowCells()
            self:ApplyBorderAnchors()
            if self.viewMode == "overview" and self.RefreshOverviewLayout then
                self:RefreshOverviewLayout()
            end
        end)

        f:Hide()
        return f
    end

    -- ========================================================================
    -- Show / Hide / Toggle (с учётом viewMode)
    -- ========================================================================
    function QuestsField:Show()
        self:EnsureFrame()

        -- Скрыть тултип (на случай, если он висел от прошлого показа)
        GameTooltip:Hide()

        -- Если включён overview — показать overview, а не детальный вид
        if self.viewMode == "overview" and self.ShowOverview then
            self.frame:Show()
            self:ShowOverview()
            return
        end

        -- Обычный детальный вид
        self.frame:Show()

        if NSQC4.QuestsDfTerrain then NSQC4.QuestsDfTerrain:Render() end
        if NSQC4.QuestsDfEntities then NSQC4.QuestsDfEntities:Render() end
        if NSQC4.QuestsDfTransformDrops then NSQC4.QuestsDfTransformDrops:RenderAll() end
    end

    function QuestsField:Hide()
        -- Скрыть overview (если был) — чтобы при следующем Show
        -- не остались «большие» квадраты поверх клеток
        if self.viewMode == "overview" and self.HideOverview then
            self:HideOverview()
        end

        GameTooltip:Hide()

        if self.frame then self.frame:Hide() end
    end

    function QuestsField:Toggle()
        self:EnsureFrame()
        if self.frame:IsShown() then
            self:Hide()
        else
            self:Show()
        end
    end

    -- ========================================================================
    -- Крестик
    -- ========================================================================
    function QuestsField:CreateCloseButton()
        local f = self.frame
        local btn = CreateFrame("Button", "NSQC4FieldClose", f, "UIPanelCloseButton")
        btn:SetSize(32, 32)
        btn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
        btn:SetFrameLevel(f:GetFrameLevel() + 30)
        btn:SetAlpha(0.01)

        btn:SetScript("OnEnter", function(self2) self2:SetAlpha(1) end)
        btn:SetScript("OnLeave", function(self2) self2:SetAlpha(0.01) end)
        btn:SetScript("OnClick", function()
            self:Hide()
        end)

        self.closeBtn = btn
        return btn
    end
end)