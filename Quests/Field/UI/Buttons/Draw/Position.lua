-- ============================================================================
-- NSQC4 / Quests / Field / UI / Buttons / Draw / Position
-- Одна логика: установка позиции кнопки на поле.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    -- Ставит кнопку в нужную точку (side + cellIndex)
    function QuestsField:SetButtonPosition(rec, cellIndex)
        local f = self.frame
        if not f then return false end

        local cx, cy = self:PanelButtonXY(rec.side, cellIndex)
        if not cx then return false end

        rec.texture:ClearAllPoints()
        rec.texture:SetPoint("CENTER", f, "BOTTOMLEFT", cx, cy)
        return true
    end

end, 462)