-- ============================================================================
-- NSQC4 / Quests / Field / Border / Backdrop
-- Одна логика: подложка-рамка (только визуал, без мыши).
--
-- Подложка — ТЕКСТУРА на field.frame, sublevel -1 (ниже клеток и кнопок).
-- Заголовок — FontString на field.frame, OVERLAY.
-- Никакой дочерний frame не создаётся, поэтому кнопки (OVERLAY 10)
-- и свитчеры (OVERLAY 11) всегда выше подложки.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    function QuestsField:CreateBackdrop()
        if self.backdrop then return self.backdrop end

        local f = self.frame
        if not f then return nil end

        -- подложка (текстура, sublevel -1 — ниже клеток 0 и кнопок 10)
        local tex = f:CreateTexture(nil, "BACKGROUND", nil, -1)
        tex:SetAllPoints(f)
        tex:SetTexture("Interface\\Buttons\\WHITE8x8")
        tex:SetVertexColor(0, 0, 0, 0.85)

        -- заголовок (над полем)
        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("BOTTOM", f, "TOP", 0, 4)
        title:SetText("|cffffd100Поле квестов|r |cff808080(ЛКМ — тянуть, ПКМ — рамка)|r")

        self.backdrop      = tex
        self.backdropTitle = title

        if self.SetBorderVisible then
            self:SetBorderVisible(self.borderVisible)
        end

        return tex
    end

end, 350)