-- ============================================================================
-- NSQC4 / Quests / Field / UI / Buttons / Widget / Draw
-- Одна логика: отрисовать кнопку на parent в позиции y.
--
--   UIButton:Draw(parent, rec, y, availableW) → height
--
-- Высота блока возвращается для раскладки (LayoutWindow).
-- Фрейм/текстура создаются лениво при первом Draw.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local UIButton = NSQC4.UIButton
    if not UIButton then return end

    local BUTTON_H = 24

    function UIButton:Draw(parent, rec, y, availableW)
        if not parent then return 0 end

        if not rec.frame then
            local tex = parent:CreateTexture(nil, "OVERLAY")
            tex:SetTexture("Interface\\Buttons\\WHITE8x8")
            tex:SetVertexColor(0.4, 0, 0, 1)

            local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            fs:SetText(rec.label)
            fs:SetPoint("CENTER", tex, "CENTER", 0, 0)

            rec.frame = tex
            rec.text  = fs
        end

        rec.frame:ClearAllPoints()
        rec.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y)
        rec.frame:SetSize(availableW, BUTTON_H)
        rec.frame:Show()

        if rec.text then rec.text:Show() end

        return BUTTON_H + 4
    end

end, 532)