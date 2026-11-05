-- ============================================================================
-- NSQC4 / Quests / Field / UI / Border
-- Подложка-рамка: drag, ПКМ-toggle, заголовок.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

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
        b:SetScript("OnDragStart", function() f:StartMoving() end)
        b:SetScript("OnDragStop", function()
            f:StopMovingOrSizing()
            self:Save()
        end)

        self.borderFrame = b
        self:ApplyBorderAnchors()
        return b
    end
end)