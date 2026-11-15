-- ============================================================================
-- NSQC4 / Quests / Field / Switcher / Draw / Refresh
-- Одна логика: оркестрация отрисовки свитчеров.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    function QuestsField:RefreshSwitchers()
        local list = self._switchers
        if not list then return end

        local f = self.frame
        if not f then return end

        for _, rec in ipairs(list) do
            if self:ShouldShowSwitcher(rec) then
                if self:PositionSwitcher(rec) then
                    rec.texture:Show()
                else
                    rec.texture:Hide()
                end
            else
                rec.texture:Hide()
            end
        end
    end

end, 613)