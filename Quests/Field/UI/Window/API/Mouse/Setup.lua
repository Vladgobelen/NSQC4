-- ============================================================================
-- NSQC4 / Quests / Field / UI / Window / API / Mouse / Setup
-- Одна логика: навесить скрипты OnMouseDown / OnMouseUp на окно.
-- Все они сводятся к DispatchWindowMouse.
--
--   W:SetupWindowMouse(win)   -- идемпотентно (win._mouseSetup)
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local W = NSQC4.FieldWindow
    if not W then return end

    function W:SetupWindowMouse(win)
        if not win or win._mouseSetup then return end
        win._mouseSetup = true
        win._mouseHandlers = win._mouseHandlers or {}

        win:EnableMouse(true)

        win:SetScript("OnMouseDown", function(_, button)
            W:DispatchWindowMouse(win, button, "down")
        end)

        win:SetScript("OnMouseUp", function(_, button)
            W:DispatchWindowMouse(win, button, "up")
        end)
    end

end, 497)