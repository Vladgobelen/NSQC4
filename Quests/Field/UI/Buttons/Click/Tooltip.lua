-- ============================================================================
-- NSQC4 / Quests / Field / UI / Buttons / Click / Tooltip
-- Одна логика: показ/скрытие тултипа кнопки панели (СКМ).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    function QuestsField:ToggleTooltipButton(rec)
        if not rec then return end

        if self._tooltipTarget == rec then
            self._tooltipTarget = nil
            GameTooltip:Hide()
            return
        end

        self._tooltipTarget = rec

        local tip = rec.settings.tooltip
            or (rec.settings.opts and rec.settings.opts.tooltip)

        if tip and self.frame then
            GameTooltip:SetOwner(self.frame, "ANCHOR_CURSOR")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(tip, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end

end, 469)