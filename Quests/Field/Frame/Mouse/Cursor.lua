-- ============================================================================
-- NSQC4 / Quests / Field / Frame / Mouse / Cursor
-- Одна логика: координаты курсора в системе frame.
--
--   CursorInFrame() → x, y | nil
--     x, y — пиксели от BOTTOMLEFT frame (0,0)
--     nil  — если frame не создан или не имеет геометрии
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

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

end, 391)