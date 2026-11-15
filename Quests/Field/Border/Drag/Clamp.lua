-- ============================================================================
-- NSQC4 / Quests / Field / Border / Drag / Clamp
-- Одна логика: удержание frame в пределах экрана.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local QuestsField = NSQC4.QuestsFieldClass
    local CONST       = NSQC4.QuestsFieldConst
    if not QuestsField or not CONST then return end

    local GRID_PADDING = CONST.GRID_PADDING

    function QuestsField:ClampFrameToScreen()
        local frame = self.frame
        if not frame then return end

        local left   = frame:GetLeft()   or 0
        local right  = frame:GetRight()  or 0
        local top    = frame:GetTop()    or 0
        local bottom = frame:GetBottom() or 0

        local pad = GRID_PADDING
        local uiW = UIParent:GetWidth()
        local uiH = UIParent:GetHeight()

        local dx, dy = 0, 0
        if left + pad < 0 then dx = -(left + pad) end
        if right - pad > uiW then dx = uiW - (right - pad) end
        if bottom + pad < 0 then dy = -(bottom + pad) end
        if top - pad > uiH then dy = uiH - (top - pad) end

        if dx ~= 0 or dy ~= 0 then
            local x = frame:GetLeft()   or 0
            local y = frame:GetBottom() or 0
            frame:ClearAllPoints()
            frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x + dx, y + dy)
        end
    end
end, 371)