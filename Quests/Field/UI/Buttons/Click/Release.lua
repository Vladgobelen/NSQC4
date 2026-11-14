-- ============================================================================
-- NSQC4 / Quests / Field / UI / Buttons / Click / Release
-- Одна логика: отпускание мыши (снять анимацию нажатия).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    function QuestsField:OnMouseUp()
        self:ReleaseTexture()
    end

end, 468)