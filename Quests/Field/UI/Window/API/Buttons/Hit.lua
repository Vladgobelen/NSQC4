-- ============================================================================
-- NSQC4 / Quests / Field / UI / Window / API / Buttons / Hit
-- Одна логика: хит-тест кнопок окна по геометрии + регистрация обработчика.
--
--   W:AttachButtonMouse(win, windowId)
--
-- event "up"   → UIButton:Release()
-- event "down" → хит-тест по кнопкам windowId → Press + onClick
--
-- Использует W:AddWindowMouseHandler (API/Mouse/Register.lua, 494).
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local W        = NSQC4.FieldWindow
    local UIButton = NSQC4.UIButton
    if not W or not UIButton then return end

    function W:AttachButtonMouse(win, windowId)
        if not win or win._buttonsMouseAttached then return end
        win._buttonsMouseAttached = true

        self:AddWindowMouseHandler(win, function(x, y, button, event)
            if event ~= "down" then
                if event == "up" then
                    UIButton:Release()
                end
                return false
            end

            if button ~= "LeftButton" then return false end

            local items = self._items and self._items[windowId]
            if not items then return false end

            local winLeft, winBottom = win:GetLeft(), win:GetBottom()
            if not winLeft or not winBottom then return false end
            local screenX = winLeft + x
            local screenY = winBottom + y

            for _, rec in pairs(items) do
                if rec.kind == "button" and rec.frame and rec.frame:IsShown() then
                    local l = rec.frame:GetLeft()
                    local r = rec.frame:GetRight()
                    local t = rec.frame:GetTop()
                    local b = rec.frame:GetBottom()
                    if l and r and t and b
                       and screenX >= l and screenX <= r
                       and screenY >= b and screenY <= t then
                        UIButton:Press(rec)
                        if rec.onClick then rec.onClick(button) end
                        return true
                    end
                end
            end

            return false
        end)
    end

end, 561)