-- ============================================================================
-- NSQC4 / Quests / Field / Close / Button
-- Одна логика: крестик в правом верхнем углу поля.
--
--   QuestsField:CreateCloseButton()  -- создать (один раз)
--
-- UIPanelCloseButton, SetSize(32,32), TOPRIGHT (-2, -2).
-- SetAlpha(0.01) в покое, 1 при наведении.
-- OnClick → self:Hide().
-- SetFrameLevel(self.frame:GetFrameLevel() + 30) — выше подложки.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    function QuestsField:CreateCloseButton()
        if self.closeBtn then return self.closeBtn end

        local f = self.frame
        if not f then return nil end

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

end, 430)