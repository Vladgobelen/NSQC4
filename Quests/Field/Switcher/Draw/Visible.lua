-- ============================================================================
-- NSQC4 / Quests / Field / Switcher / Draw / Visible
-- Одна логика: вычисление видимости свитчера.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    function QuestsField:ShouldShowSwitcher(rec)
        local side = rec.side
        local v    = (rec.settings and rec.settings.visible) or 1

        local visibleNow = true
        if v == 2 then
            visibleNow = (self.borderVisible == true)
        elseif v == 3 then
            visibleNow = (self.borderVisible == false)
        end

        -- Скрываем, если на текущей панели стороны нет кнопок
        if visibleNow and not self:HasPanelButtons(side) then
            visibleNow = false
        end

        return visibleNow
    end

end, 611)