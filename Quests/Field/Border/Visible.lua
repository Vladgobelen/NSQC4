-- ============================================================================
-- NSQC4 / Quests / Field / Border / Visible
-- Одна логика: видимость подложки (alpha 1 ↔ 0.01).
--
--   SetBorderVisible(v)     -- v = true → alpha 1 + title Show
--                             -- v = false → alpha 0.01 + title Hide
--   ToggleBorderVisible()   -- SetBorderVisible(not IsBorderVisible())
--   IsBorderVisible()       -- true | false
--
-- Подложка — текстура (Border/Backdrop.lua), self.backdrop.
-- Заголовок — FontString, self.backdropTitle.
--
-- Сохранение — в nsDbc4.quests.field.borderVisible (boolean).
-- Загрузка — при Load() (Core/Storage.lua) в self.borderVisible.
--
-- После смены — пересчёт кнопок панелей (opts.visible 2/3) и свитчеров.
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
            b:SetAlpha(0.01)
            if self.backdropTitle then self.backdropTitle:Hide() end
        end

        self:Save()

        if self.RefreshAllButtons then self:RefreshAllButtons() end
        if self.RefreshSwitchers   then self:RefreshSwitchers()   end
    end

    function QuestsField:ToggleBorderVisible()
        self:SetBorderVisible(not self:IsBorderVisible())
    end

end, 360)