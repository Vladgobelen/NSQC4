-- ============================================================================
-- NSQC4 / Quests / Field / Switcher / Draw / Position
-- Одна логика: установка позиции и размера свитчера.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    local FIRST_CELL = {
        TOP    = 91,
        RIGHT  = 100,
        LEFT   = 91,
        BOTTOM = 1,
    }

    function QuestsField:PositionSwitcher(rec)
        local f = self.frame
        if not f then return false end

        local cx, cy = self:PanelButtonXY(rec.side, FIRST_CELL[rec.side])
        if not cx then return false end

        rec.texture:ClearAllPoints()
        rec.texture:SetPoint("CENTER", f, "BOTTOMLEFT", cx, cy)

        if not self:IsPressed(rec.texture) then
            local bs = self:GetButtonSize()
            rec.texture:SetSize(bs, bs)
        end

        return true
    end

end, 612)