-- ============================================================================
-- NSQC4 / Quests / Field / Frame / Mouse
-- Одна логика: мышь. Только события OnMouseDown / OnMouseUp / OnMouseWheel
-- и координаты курсора в системе frame. Куда попал и что делать —
-- решают обработчики, зарегистрированные через API:
--   self:AddMouseHandler(fn)   -- fn(x, y, button, event) → true, если поглотил
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    -- ========================================================================
    -- API: регистрация обработчика мыши.
    --   fn(x, y, button, event)
    --     x, y   — координаты курсора в системе frame (BOTTOMLEFT = 0,0)
    --     button — "LeftButton" | "RightButton" | "MiddleButton"
    --     event  — "down" | "up" | "wheel"
    --   Возврат true — событие поглощено, следующие обработчики не зовутся.
    -- ========================================================================
    function QuestsField:AddMouseHandler(fn)
        if type(fn) ~= "function" then return end
        self._mouseHandlers = self._mouseHandlers or {}
        self._mouseHandlers[#self._mouseHandlers + 1] = fn
    end

    -- ========================================================================
    -- Координаты курсора в системе frame.
    -- ========================================================================
    function QuestsField:CursorInFrame()
        local f = self.frame
        if not f then return nil end
        local scale = UIParent:GetEffectiveScale()
        local cx, cy = GetCursorPosition()
        cx, cy = cx / scale, cy / scale
        local left, bottom = f:GetLeft(), f:GetBottom()
        if not left or not bottom then return nil end
        return cx - left, cy - bottom
    end

    local function Dispatch(self, button, event)
        local x, y = self:CursorInFrame()
        if not x then return end
        local handlers = self._mouseHandlers
        if not handlers then return end
        for _, fn in ipairs(handlers) do
            if fn(x, y, button, event) then return end
        end
    end

    -- ========================================================================
    -- SetupMouse — повесить скрипты на frame.
    -- ========================================================================
    function QuestsField:SetupMouse()
        local f = self.frame
        if not f then return end
        f:EnableMouse(true)
        f:EnableMouseWheel(true)

        f:SetScript("OnMouseDown", function(_, button)
            Dispatch(self, button, "down")
        end)

        f:SetScript("OnMouseUp", function(_, button)
            Dispatch(self, button, "up")
        end)

        f:SetScript("OnMouseWheel", function(_, delta)
            Dispatch(self, delta > 0 and "WheelUp" or "WheelDown", "wheel")
        end)
    end

end, 390)