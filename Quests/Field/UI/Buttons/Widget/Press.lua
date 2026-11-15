-- ============================================================================
-- NSQC4 / Quests / Field / UI / Buttons / Widget / Press
-- Одна логика: анимация нажатия кнопки (уменьшение/восстановление размера).
--
--   UIButton:Press(rec)     — уменьшить на PIXELS*2, запомнить исходный размер
--   UIButton:Release()      — вернуть исходный размер
--
-- _pressed хранит только одну активную кнопку — этого достаточно,
-- т.к. мышь нажата максимум на одной кнопке за раз.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local UIButton = NSQC4.UIButton
    if not UIButton then return end

    local PIXELS = 2

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

end, 533)