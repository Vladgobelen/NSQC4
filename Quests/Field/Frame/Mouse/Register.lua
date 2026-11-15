-- ============================================================================
-- NSQC4 / Quests / Field / Frame / Mouse / Register
-- Одна логика: API регистрации обработчиков мыши.
--
--   self:AddMouseHandler(fn)   -- fn(x, y, button, event) → true, если поглотил
--
--   x, y   — координаты курсора в системе frame (BOTTOMLEFT = 0,0)
--   button — "LeftButton" | "RightButton" | "MiddleButton"
--   event  — "down" | "up" | "wheel"
--
-- Возврат true — событие поглощено, следующие обработчики не зовутся.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    function QuestsField:AddMouseHandler(fn)
        if type(fn) ~= "function" then return end
        self._mouseHandlers = self._mouseHandlers or {}
        self._mouseHandlers[#self._mouseHandlers + 1] = fn
    end

end, 390)