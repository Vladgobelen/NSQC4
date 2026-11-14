-- ============================================================================
-- NSQC4 / Quests / Field / UI / Buttons / Init
-- Универсальный рендерер кнопок.
--
-- НИЧЕГО не знает о поле (QuestsField) и об окнах (FieldWindow).
-- Рисует кнопки на любом parent-фрейме, где скажут.
--
-- НЕ регистрирует мышь (это делает Settings/Init.lua для окон).
--
-- Публичный API (NSQC4.UIButton):
--   CreateRecord(label, onClick, opts)       → rec
--   Draw(parent, rec, y, availableW)         → height
--   Press(rec)
--   Release()
-- ============================================================================
NSQC4.RegisterModule("quests", function()
    local UIButton = {}
    NSQC4.UIButton = UIButton

    local BUTTON_H = 24
    local PIXELS   = 2

    -- ========================================================================
    -- CreateRecord — создать запись кнопки (без отрисовки).
    -- ========================================================================
    function UIButton:CreateRecord(label, onClick, opts)
        return {
            kind    = "button",
            label   = label,
            onClick = onClick,
            opts    = opts or {},
        }
    end

    -- ========================================================================
    -- Draw — отрисовать кнопку на parent в позиции y.
    -- Возвращает высоту блока (для раскладки).
    -- ========================================================================
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

    -- ========================================================================
    -- Press / Release — анимация нажатия.
    -- ========================================================================
    function UIButton:Press(rec)
        if not rec or not rec.frame then return end

        local tex = rec.frame
        local w, h = tex:GetWidth(), tex:GetHeight()
        if not w or not h then return end

        tex:SetSize(w - PIXELS * 2, h - PIXELS * 2)
        self._pressed = { tex = tex, w = w, h = h }
    end

    function UIButton:Release()
        local p = self._pressed
        if not p then return end

        self._pressed = nil
        if p.tex and p.w and p.h then
            p.tex:SetSize(p.w, p.h)
        end
    end
end, 530)