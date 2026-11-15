-- ============================================================================
-- NSQC4 / Quests / Field / UI / Window / API / Mouse / Dispatch
-- Одна логика: передача события всем зарегистрированным обработчикам окна
-- по цепочке, пока кто-то не вернёт true (поглотил).
--
--   W:DispatchWindowMouse(win, button, event)
--     button — "LeftButton" | "RightButton" | "MiddleButton"
--     event  — "down" | "up"
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local W = NSQC4.FieldWindow
    if not W then return end

    function W:DispatchWindowMouse(win, button, event)
        if not win then return end
        local x, y = self:CursorInWindow(win)
        if not x then return end
        local handlers = win._mouseHandlers
        if not handlers then return end
        for _, fn in ipairs(handlers) do
            if fn(x, y, button, event) then return end
        end
    end

end, 496)