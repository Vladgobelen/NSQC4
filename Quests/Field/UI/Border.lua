-- ============================================================================
-- NSQC4 / Quests / Field / UI / Border
-- Подложка-рамка: drag, ПКМ-toggle, заголовок.
--
-- DRAG:
--   SetClampedToScreen(false) на фрейме — рамка может выходить за экран.
--   OnDragStop в Border — вручную прижимает фрейм так, чтобы КЛЕТКИ
--   (без GRID_PADDING) были внутри экрана. Рамка (GRID_PADDING) может
--   выходить за край.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local QuestsField = NSQC4.QuestsFieldClass
    local CONST       = NSQC4.QuestsFieldConst
    if not QuestsField or not CONST then return end

    local GRID_PADDING = CONST.GRID_PADDING or 40

    function QuestsField:ApplyBorderAnchors()
        local b, f = self.borderFrame, self.frame
        if not b or not f then return end
        b:ClearAllPoints()
        b:SetAllPoints(f)
    end

    function QuestsField:SetBorderVisible(visible)
        local b = self.borderFrame
        if not b then return end
        self.borderVisible = visible and true or false
        if self.borderVisible then
            b:SetAlpha(1)
            if b.title then b.title:Show() end
        else
            b:SetAlpha(0.01)
            if b.title then b.title:Hide() end
        end
        self:Save()
    end

    -- ========================================================================
    -- OnDragStop: прижать фрейм так, чтобы КЛЕТКИ (без GRID_PADDING) были
    -- внутри экрана. Рамка (GRID_PADDING) может выходить за край.
    -- ========================================================================
    local function ClampToCells(frame)
        local left   = frame:GetLeft()   or 0
        local right  = frame:GetRight()  or 0
        local top    = frame:GetTop()    or 0
        local bottom = frame:GetBottom() or 0

        local pad = GRID_PADDING
        local uiW = UIParent:GetWidth()
        local uiH = UIParent:GetHeight()

        local dx, dy = 0, 0

        -- клетки внутри: left+pad >= 0, right-pad <= uiW
        if left + pad < 0 then dx = -(left + pad) end
        if right - pad > uiW then dx = uiW - (right - pad) end
        -- клетки внутри: bottom+pad >= 0, top-pad <= uiH
        if bottom + pad < 0 then dy = -(bottom + pad) end
        if top - pad > uiH then dy = uiH - (top - pad) end

        if dx ~= 0 or dy ~= 0 then
            local x, y = frame:GetLeft(), frame:GetBottom()
            frame:ClearAllPoints()
            frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT",
                (x or 0) + dx, (y or 0) + dy)
        end
    end

    function QuestsField:CreateBorder()
        local f = self.frame
        local b = CreateFrame("Frame", "NSQC4FieldBorder", f)
        b:SetFrameLevel(f:GetFrameLevel() + 5)
        b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        b:SetBackdropColor(0, 0, 0, 0.85)
        b:SetAlpha(0.01)
        b:EnableMouse(true)

        local title = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("BOTTOM", b, "TOP", 0, 4)
        title:SetText("|cffffd100Поле квестов|r |cff808080(ПКМ — рамка, ЛКМ — тянуть)|r")
        title:Hide()
        b.title = title

        b:SetScript("OnMouseDown", function(_, button)
            if button ~= "RightButton" then return end
            self:SetBorderVisible(not self.borderVisible)
        end)

        b:RegisterForDrag("LeftButton")
        b:SetScript("OnDragStart", function()
            f:StartMoving()
        end)
        b:SetScript("OnDragStop", function()
            f:StopMovingOrSizing()
            -- прижать так, чтобы клетки (без GRID_PADDING) были внутри
            ClampToCells(f)
            self:Save()
        end)

        self.borderFrame = b
        self:ApplyBorderAnchors()
        return b
    end
end)