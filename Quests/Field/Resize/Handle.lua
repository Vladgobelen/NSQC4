-- ============================================================================
-- NSQC4 / Quests / Field / Resize / Handle
-- Одна логика: хэндл 16×16 в правом нижнем углу поля.
--
--   QuestsField:CreateResizeHandle()  -- создать (один раз)
--
--   OnMouseDown (ЛКМ) — запомнить anchorL = frame:GetLeft(),
--                       anchorT = frame:GetTop(), начать OnUpdate.
--   OnUpdate — если ЛКМ отпущена: снять OnUpdate, Save().
--              иначе: GetCursorPosition / scale → ApplyResize(cx, cy, aL, aT).
--
-- Текстуры: UI-ChatIM-SizeGrabber-Up/Down/Highlight.
-- SetFrameLevel(self.frame:GetFrameLevel() + 30) — выше подложки и клеток.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    function QuestsField:CreateResizeHandle()
        if self.resizeHandle then return self.resizeHandle end

        local f = self.frame
        if not f then return nil end

        local h = CreateFrame("Button", "NSQC4FieldResize", f)
        h:SetSize(16, 16)
        h:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 4, -4)
        h:SetFrameLevel(f:GetFrameLevel() + 30)
        h:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        h:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        h:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        h:EnableMouse(true)

        local anchorL, anchorT

        h:SetScript("OnMouseDown", function(_, button)
            if button ~= "LeftButton" then return end
            anchorL = f:GetLeft()
            anchorT = f:GetTop()

            h:SetScript("OnUpdate", function()
                if not IsMouseButtonDown("LeftButton") then
                    h:SetScript("OnUpdate", nil)
                    self:Save()
                    return
                end
                local scale = UIParent:GetEffectiveScale()
                local cx, cy = GetCursorPosition()
                cx, cy = cx / scale, cy / scale
                self:ApplyResize(cx, cy, anchorL, anchorT)
            end)
        end)

        h:SetScript("OnHide", function(self2)
            self2:SetScript("OnUpdate", nil)
        end)

        self.resizeHandle = h
        return h
    end

end, 420)