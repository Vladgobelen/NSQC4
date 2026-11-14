-- ============================================================================
-- NSQC4 / Quests / Field / Border / Visible
-- Одна логика: видимость подложки (alpha 1 ↔ 0.1) и заголовка.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    function QuestsField:IsBorderVisible()
        return self.borderVisible and true or false
    end

    function QuestsField:SetBorderVisible(v)
        local b = self.backdrop
        if not b then return end

        self.borderVisible = v and true or false

        if self.borderVisible then
            b:SetAlpha(1)
            if self.backdropTitle then self.backdropTitle:Show() end
        else
            b:SetAlpha(0.1)
            if self.backdropTitle then self.backdropTitle:Hide() end
        end

        -- Сохраняем флаг (не всю геометрию)
        if self.SaveFlag then
            self:SaveFlag("borderVisible", self.borderVisible)
        end
    end

    function QuestsField:ToggleBorderVisible()
        self:SetBorderVisible(not self:IsBorderVisible())
    end

end, 360)