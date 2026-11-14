-- ============================================================================
-- NSQC4 / Quests / Field / UI / Buttons / Draw / Visible
-- Одна логика: вычисление видимости кнопки панели.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    -- Возвращает true, если кнопку нужно показать
    function QuestsField:ShouldShowButton(data)
        -- 1. Проверка панели
        local show = (data.panelIndex == self:GetPanelIndex(data.side))
        if not show then return false end

        -- 2. Проверка opts.visible (1/2/3)
        local v = (data.opts and data.opts.visible) or 1
        if v == 2 then
            return self.borderVisible == true
        elseif v == 3 then
            return self.borderVisible == false
        end

        return true
    end

end, 461)