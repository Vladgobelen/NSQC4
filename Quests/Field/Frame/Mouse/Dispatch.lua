-- ============================================================================
-- NSQC4 / Quests / Field / Frame / Mouse / Dispatch
-- Одна логика: передача события всем зарегистрированным обработчикам
-- по цепочке, пока кто-то не вернёт true (поглотил).
--
--   Dispatch(self, button, event)
--     button — "LeftButton" | "RightButton" | "MiddleButton" | "WheelUp" | "WheelDown"
--     event  — "down" | "up" | "wheel"
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    function QuestsField:DispatchMouse(button, event)
        local x, y = self:CursorInFrame()
        if not x then return end
        local handlers = self._mouseHandlers
        if not handlers then return end
        for _, fn in ipairs(handlers) do
            if fn(x, y, button, event) then return end
        end
    end

end, 392)