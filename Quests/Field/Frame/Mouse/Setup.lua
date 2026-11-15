-- ============================================================================
-- NSQC4 / Quests / Field / Frame / Mouse / Setup
-- Одна логика: навесить скрипты OnMouseDown / OnMouseUp / OnMouseWheel
-- на frame. Все они сводятся к DispatchMouse.
--
-- Зависит от: Register.lua (уже создан API), Cursor.lua, Dispatch.lua.
-- Не создаёт frame — его создаёт Frame/Create.lua.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    function QuestsField:SetupMouse()
        local f = self.frame
        if not f then return end

        f:EnableMouse(true)
        f:EnableMouseWheel(true)

        f:SetScript("OnMouseDown", function(_, button)
            self:DispatchMouse(button, "down")
        end)

        f:SetScript("OnMouseUp", function(_, button)
            self:DispatchMouse(button, "up")
        end)

        f:SetScript("OnMouseWheel", function(_, delta)
            self:DispatchMouse(delta > 0 and "WheelUp" or "WheelDown", "wheel")
        end)
    end

end, 393)