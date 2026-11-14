-- ============================================================================
-- NSQC4 / Quests / Field / Switcher / Click / Hit
-- Одна логика: хит-тест свитчеров (попадание курсора).
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

    function QuestsField:HitSwitcher(x, y)
        local list = self._switchers
        if not list then return nil end

        local bs = self:GetButtonSize()

        for _, rec in ipairs(list) do
            if rec.texture:IsShown() then
                local cx, cy = self:PanelButtonXY(rec.side, FIRST_CELL[rec.side])
                if cx and x >= cx - bs/2 and x <= cx + bs/2
                       and y >= cy - bs/2 and y <= cy + bs/2 then
                    return rec
                end
            end
        end

        return nil
    end

end, 611)