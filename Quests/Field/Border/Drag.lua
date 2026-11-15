-- ============================================================================
-- NSQC4 / Quests / Field / Border / Drag
-- Одна логика: драг frame (StartDrag, StopDrag, SetupFrameDrag).
-- Кламп вынесен в Border/Drag/Clamp.lua.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

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
        if self.ClampFrameToScreen then self:ClampFrameToScreen() end
        self:Save()
    end

    function QuestsField:SetupFrameDrag()
        local f = self.frame
        if not f then return end

        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function() self:StartDrag() end)
        f:SetScript("OnDragStop",  function() self:StopDrag()  end)
    end
end, 372)