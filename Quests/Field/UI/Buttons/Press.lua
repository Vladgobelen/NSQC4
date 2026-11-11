-- ============================================================================
-- NSQC4 / Quests / Field / UI / Buttons / Press
-- Одна логика: анимация нажатия текстур-кнопок (панели, свитчеры).
--   PressTexture(tex)   — уменьшить на PIXELS*2, запомнить исходный размер
--   ReleaseTexture()    — вернуть исходный размер
--   IsPressed(tex)      — true, если эта текстура сейчас нажата
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    local PIXELS = 3

    function QuestsField:PressTexture(tex)
        if not tex then return end
        local w, h = tex:GetWidth(), tex:GetHeight()
        if not w or not h then return end
        tex:SetSize(w - PIXELS * 2, h - PIXELS * 2)
        self._pressedTex = { tex = tex, w = w, h = h }
    end

    function QuestsField:ReleaseTexture()
        local p = self._pressedTex
        if not p then return end
        self._pressedTex = nil
        if p.tex and p.w and p.h then
            p.tex:SetSize(p.w, p.h)
        end
    end

    function QuestsField:IsPressed(tex)
        local p = self._pressedTex
        return p ~= nil and p.tex == tex
    end

end, 455)