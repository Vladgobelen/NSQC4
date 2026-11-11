-- ============================================================================
-- NSQC4 / Quests / Field / Border / Click
-- Одна логика: ПКМ по frame → ToggleBorderVisible().
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    function QuestsField:SetupFrameClick()
        local f = self.frame
        if not f then return end

        f:HookScript("OnMouseDown", function(_, button)
            if button == "RightButton" then
                self:ToggleBorderVisible()
            end
        end)
    end

end, 380)