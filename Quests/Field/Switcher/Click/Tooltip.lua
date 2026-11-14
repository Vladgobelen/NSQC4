-- ============================================================================
-- NSQC4 / Quests / Field / Switcher / Click / Tooltip
-- Одна логика: показ/скрытие тултипа свитчера по СКМ.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    function QuestsField:ToggleTooltipSwitcher(sw)
        if not sw then return end

        if self._tooltipTarget == sw then
            self._tooltipTarget = nil
            GameTooltip:Hide()
            return
        end

        self._tooltipTarget = sw

        local tip = sw.settings and sw.settings.tooltip
        if tip and self.frame then
            GameTooltip:SetOwner(self.frame, "ANCHOR_CURSOR")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(tip, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end

end, 613)