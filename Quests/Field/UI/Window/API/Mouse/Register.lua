-- ============================================================================
-- NSQC4 / Quests / Field / UI / Window / API / Mouse / Register
-- Одна логика: API регистрации обработчиков мыши окна.
--
--   W:AddWindowMouseHandler(win, fn)
--     fn(x, y, button, event) → true, если поглотил
--
--   x, y   — координаты курсора в системе win (BOTTOMLEFT = 0,0)
--   button — "LeftButton" | "RightButton" | "MiddleButton"
--   event  — "down" | "up"
--
-- Возврат true — событие поглощено, следующие обработчики не зовутся.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local W = NSQC4.FieldWindow
    if not W then return end

    function W:AddWindowMouseHandler(win, fn)
        if not win or type(fn) ~= "function" then return end
        win._mouseHandlers = win._mouseHandlers or {}
        win._mouseHandlers[#win._mouseHandlers + 1] = fn
    end

end, 494)