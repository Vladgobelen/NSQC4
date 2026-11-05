-- ============================================================================
-- NSQC4 / Quests / Field / UI / Frame
-- Создание главного фрейма поля + клетки + рамка + ресайз + крестик.
--
-- ОГРАНИЧЕНИЕ РАЗМЕРА:
--   MaxCellForScreen() = min(MAX_CELL, cellSizeFromScreen),
--   cellSizeFromScreen = из 90% самой узкой стороны UIParent.
--   Применяется:
--     - в EnsureFrame (при создании фрейма)
--     - в Show (при каждом открытии — принудительно сжать, если cellSize > eff)
--     - в Resize.lua (при ресайзе — см. отдельный файл)
--
-- ОТЛАДКА:
--   /ns_frame on | off | dump
--   При on:
--     - EnsureFrame: [FRAME] EnsureFrame cs=... eff=... fromScreen=...
--     - Show:        [FRAME] Show cs=... eff=... clamp=yes/no
--     - MaxCellForScreen: [FRAME] MaxCellForScreen eff=... fromScreen=... uiW=... uiH=...
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
    local SCREEN_PERCENT = CONST.SCREEN_PERCENT or 1

    -- ========================================================================
    -- Отладка
    -- ========================================================================
    local FrameDebug = { DEBUG = false }
    QuestsField._FrameDebug = FrameDebug

    local function dbg(...)
        if FrameDebug.DEBUG then print("|cff00ffff[FRAME]|r", ...) end
    end

    -- ========================================================================
    -- Размер фрейма по cellSize
    -- ========================================================================
    local function FrameSizeForCell(cs)
        return cs * COLS + (COLS - 1) * CELL_GAP + GRID_PADDING * 2,
               cs * ROWS + (ROWS - 1) * CELL_GAP + GRID_PADDING * 2
    end
    QuestsField._FrameSizeForCell = FrameSizeForCell

    -- ========================================================================
    -- MaxCellForScreen(): максимальный cellSize с учётом 90% самой узкой
    -- стороны UIParent. Возвращает effMaxCell, maxFromScreen.
    -- ========================================================================
    function QuestsField:MaxCellForScreen()
        local uiW = (UIParent and UIParent:GetWidth())  or 0
        local uiH = (UIParent and UIParent:GetHeight()) or 0
        local minSide = math.min(uiW, uiH)
        if minSide <= 0 then
            dbg("MaxCellForScreen: UIParent size = 0 → fallback MAX_CELL")
            return MAX_CELL, MAX_CELL
        end

        local maxSide = minSide * SCREEN_PERCENT
        local byW = (maxSide - (COLS - 1) * CELL_GAP - GRID_PADDING * 2) / COLS
        local byH = (maxSide - (ROWS - 1) * CELL_GAP - GRID_PADDING * 2) / ROWS
        local maxFromScreen = math.floor(math.min(byW, byH))

        if maxFromScreen < MIN_CELL then maxFromScreen = MIN_CELL end

        local effMaxCell = math.min(MAX_CELL, maxFromScreen)

        dbg(string.format(
            "MaxCellForScreen: uiW=%.1f uiH=%.1f minSide=%.1f maxSide=%.1f byW=%.2f byH=%.2f fromScreen=%d eff=%d (MAX_CELL=%d)",
            uiW, uiH, minSide, maxSide, byW, byH, maxFromScreen, effMaxCell, MAX_CELL))

        return effMaxCell, maxFromScreen
    end

    -- ========================================================================
    -- Применить cellSize к фрейму (размер, клетки, рамка, якоря, лут)
    -- ========================================================================
    function QuestsField:ApplyCellSize(cs)
        if not self.frame then return end
        self.cellSize = cs
        local w, h = FrameSizeForCell(cs)
        self.frame:SetSize(w, h)
        self:ReflowCells()
        self:ApplyBorderAnchors()
        if self.RefreshAllAnchorSizes then self:RefreshAllAnchorSizes() end
        local Drops = NSQC4.QuestsDfTransformDrops
        if Drops and Drops.RefreshAllLootSizes then Drops:RefreshAllLootSizes() end

        dbg(string.format("ApplyCellSize: cs=%d frame=%dx%d", cs, w, h))
    end

    -- ========================================================================
    -- EnsureFrame
    -- ========================================================================
    function QuestsField:EnsureFrame()
        if self.frame then return self.frame end

        if not self.saved then self:Load() end
        local saved = self.saved or {}

        local effMaxCell, maxFromScreen = self:MaxCellForScreen()

        local cs = math.floor((saved.cellSize or DEFAULT_CELL) + 0.5)
        if cs < MIN_CELL then cs = MIN_CELL end
        local csBefore = cs
        if cs > effMaxCell then cs = effMaxCell end

        dbg(string.format(
            "EnsureFrame: saved.cellSize=%s csBefore=%d → cs=%d (eff=%d fromScreen=%d) clamped=%s",
            tostring(saved.cellSize), csBefore, cs, effMaxCell, maxFromScreen,
            (csBefore ~= cs) and "YES" or "no"))

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

        for index = 1, COLS * ROWS do
            self.cells[index] = self:CreateCell(index)
        end
        self:ReflowCells()

        self:CreateBorder()
        self:CreateResizeHandle()
        self:CreateCloseButton()

        if saved.borderVisible then
            self.borderVisible = false
            self:SetBorderVisible(true)
        end

        f:HookScript("OnSizeChanged", function()
            self:ReflowCells()
            self:ApplyBorderAnchors()
            if self.RefreshAllAnchorSizes then self:RefreshAllAnchorSizes() end
            local Drops = NSQC4.QuestsDfTransformDrops
            if Drops and Drops.RefreshAllLootSizes then Drops:RefreshAllLootSizes() end
            if self.viewMode == "overview" and self.RefreshOverviewLayout then
                self:RefreshOverviewLayout()
            end
        end)

        f:Hide()

        dbg(string.format("EnsureFrame: created frame %dx%d at cellSize=%d", w0, h0, cs))
        return f
    end

    -- ========================================================================
    -- Show / Hide / Toggle
    -- ========================================================================
    function QuestsField:Show()
        self:EnsureFrame()

        GameTooltip:Hide()

        -- Принудительно обрезать при открытии, если cellSize > eff
        local effMaxCell, maxFromScreen = self:MaxCellForScreen()
        if self.cellSize and self.cellSize > effMaxCell then
            local csBefore = self.cellSize
            dbg(string.format(
                "Show: clamp cellSize %d → %d (eff=%d fromScreen=%d)",
                csBefore, effMaxCell, effMaxCell, maxFromScreen))
            self:ApplyCellSize(effMaxCell)
            self:Save()
        else
            dbg(string.format(
                "Show: cellSize=%s eff=%d fromScreen=%d — без clamp",
                tostring(self.cellSize), effMaxCell, maxFromScreen))
        end

        if self.viewMode == "overview" and self.ShowOverview then
            self.frame:Show()
            self:ShowOverview()
            return
        end

        self.frame:Show()

        if NSQC4.QuestsDfTerrain then NSQC4.QuestsDfTerrain:Render() end
        if NSQC4.QuestsDfEntities then NSQC4.QuestsDfEntities:Render() end
        if NSQC4.QuestsDfTransformDrops then NSQC4.QuestsDfTransformDrops:RenderAll() end
    end

    function QuestsField:Hide()
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

    -- ========================================================================
    -- Слэш-команда: /ns_frame on | off | dump
    -- ========================================================================
    SLASH_NSFRAME1 = "/ns_frame"
    SlashCmdList["NSFRAME"] = function(msg)
        local cmd = (msg or ""):lower():match("^(%S*)")
        if cmd == "on" then
            FrameDebug.DEBUG = true
            print("[FRAME] DEBUG = true")
            local e, m = NSQC4.QuestsField:MaxCellForScreen()
            print(string.format("[FRAME] eff=%d fromScreen=%d MAX_CELL=%d MIN_CELL=%d SCREEN_PERCENT=%s",
                e, m, NSQC4.QuestsFieldConst.MAX_CELL, NSQC4.QuestsFieldConst.MIN_CELL,
                tostring(NSQC4.QuestsFieldConst.SCREEN_PERCENT)))
        elseif cmd == "off" then
            FrameDebug.DEBUG = false
            print("[FRAME] DEBUG = false")
        elseif cmd == "dump" then
            local F = NSQC4.QuestsField
            local e, m = F:MaxCellForScreen()
            print(string.format(
                "[FRAME] dump: cellSize=%s frameW=%s frameH=%s eff=%d fromScreen=%d",
                tostring(F.cellSize),
                tostring(F.frame and F.frame:GetWidth() or "nil"),
                tostring(F.frame and F.frame:GetHeight() or "nil"),
                e, m))
        else
            print("[FRAME] /ns_frame on | off | dump")
        end
    end

end)