-- ============================================================================
-- NSQC4 / Quests / Field / Switcher / Click / Action
-- Одна логика: переключение панели по клику (ЛКМ вперёд, ПКМ назад).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    function QuestsField:OnSwitcherClick(sw, button)
        if not sw then return end

        if button == "LeftButton" then
            self:SwitchPanel(sw.side, 1)
        elseif button == "RightButton" then
            self:SwitchPanel(sw.side, -1)
        end

        if self.RefreshSwitchers  then self:RefreshSwitchers()  end
        if self.RefreshAllButtons then self:RefreshAllButtons() end
    end

end, 612)