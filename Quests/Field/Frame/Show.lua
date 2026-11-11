-- ============================================================================
-- NSQC4 / Quests / Field / Frame / Show
-- Одна логика: Show / Hide / Toggle.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    function QuestsField:Show()
        if not self.frame then self:CreateFrame() end
        if not self.frame then return end
        self.frame:Show()
    end

    function QuestsField:Hide()
        if self.frame then self.frame:Hide() end
    end

    function QuestsField:Toggle()
        if not self.frame then
            self:Show()
            return
        end
        if self.frame:IsShown() then
            self:Hide()
        else
            self:Show()
        end
    end

end, 310)