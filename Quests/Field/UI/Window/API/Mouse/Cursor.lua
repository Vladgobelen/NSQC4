-- ============================================================================
-- NSQC4 / Quests / Field / UI / Window / API / Mouse / Cursor
-- Одна логика: координаты курсора в системе окна.
--
--   W:CursorInWindow(win) → x, y | nil
--     x, y — пиксели от BOTTOMLEFT окна (0,0)
--     nil  — если окно не имеет геометрии
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local W = NSQC4.FieldWindow
    if not W then return end

    function W:CursorInWindow(win)
        if not win then return nil end
        local scale = UIParent:GetEffectiveScale()
        local cx, cy = GetCursorPosition()
        cx, cy = cx / scale, cy / scale
        local left, bottom = win:GetLeft(), win:GetBottom()
        if not left or not bottom then return nil end
        return cx - left, cy - bottom
    end

end, 495)