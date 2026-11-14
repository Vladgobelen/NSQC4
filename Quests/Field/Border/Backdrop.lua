NSQC4.RegisterModule("quests", function()
    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    function QuestsField:CreateBackdrop()
        if self.backdrop then return self.backdrop end

        local f = self.frame
        if not f then return nil end

        -- Создаем ОТДЕЛЬНЫЙ фрейм для подложки
        local bgFrame = CreateFrame("Frame", nil, f)
        
        -- ЖЕСТКО ставим его на самый низкий FrameLevel
        bgFrame:SetFrameLevel(1) 
        bgFrame:SetAllPoints(f)

        -- Рисуем текстуру внутри этого фрейма
        local tex = bgFrame:CreateTexture(nil, "BACKGROUND")
        tex:SetAllPoints(bgFrame)
        tex:SetTexture("Interface\\Buttons\\WHITE8x8")
        tex:SetVertexColor(0, 0, 0, 0.85)
        tex:Show()

        -- Заголовок оставляем на основном фрейме, но повыше
        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("BOTTOM", f, "TOP", 0, 4)
        title:SetText("|cffffd100Поле квестов|r |cff808080(ЛКМ — тянуть, ПКМ — рамка)|r")

        -- Сохраняем ссылку на текстуру для Visible.lua
        self.backdrop = tex
        self.backdropTitle = title
        self._backdropFrame = bgFrame -- сохраняем фрейм на всякий случай

        if self.SetBorderVisible then
            self:SetBorderVisible(self.borderVisible)
        end

        return tex
    end
end, 350)