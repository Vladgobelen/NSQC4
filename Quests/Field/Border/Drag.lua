-- ============================================================================
-- NSQC4 / Quests / Field / Border / Drag
-- Одна логика: драг frame + кламп по экрану + Save.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    local CONST       = NSQC4.QuestsFieldConst
    if not QuestsField or not CONST then return end

    local GRID_PADDING = CONST.GRID_PADDING

    local function ClampToCells(frame)
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

    function QuestsField:StartDrag()
        local f = self.frame
        if not f then return end
        self._dragging = true
        f:StartMoving()
    end

    function QuestsField:StopDrag()
        local f = self.frame
        if not f then return end
        if not self._dragging then return end
        self._dragging = false
        f:StopMovingOrSizing()
        ClampToCells(f)
        self:Save()
    end

    -- навесить драг на frame
    function QuestsField:SetupFrameDrag()
        local f = self.frame
        if not f then return end

        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function()
            self:StartDrag()
        end)
        f:SetScript("OnDragStop", function()
            self:StopDrag()
        end)
    end

end, 370)