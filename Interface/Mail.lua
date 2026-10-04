-- ============================================================================
-- NSQC4 / Interface / Mail
-- Сбор всей почты одной кнопкой в окне почты. Модуль "ui_mail".
-- ============================================================================

NSQC4.RegisterModule("ui_mail", function()

    -- Локальный флаг сбора (временный, не в БД)
    local isCollecting = false

    -- Кнопка «ЗАБРАТЬ ВСЁ»
    local btn = CreateFrame("Button", nil, UIParent, "UIPanelButtonTemplate")
    btn:SetSize(128, 23)
    btn:SetText("ЗАБРАТЬ ВСЕ")
    btn:SetFrameStrata("HIGH")
    btn:Hide()

    btn:SetScript("OnClick", function()
        isCollecting = not isCollecting
        btn:SetText(isCollecting and "..сбор.." or "ЗАБРАТЬ ВСЕ")
    end)

    -- Обработчик событий почты
    local f = CreateFrame("Frame")
    f:RegisterEvent("MAIL_SHOW")
    f:RegisterEvent("MAIL_CLOSED")
    f:RegisterEvent("MAIL_INBOX_UPDATE")
    f:SetScript("OnEvent", function()
        if MailFrame:IsVisible() and not SendMailFrame:IsVisible() then
            if not btn:IsVisible() then
                btn:ClearAllPoints()
                btn:SetPoint("TOPRIGHT", MailFrame, "TOPRIGHT", -55, -13)
                btn:Show()
            end
        else
            if btn:IsVisible() then
                btn:Hide()
                isCollecting = false
            end
            return
        end

        if InboxPrevPageButton:IsEnabled() ~= 0 then
            btn:Disable()
        else
            btn:Enable()
        end

        btn:SetText(isCollecting and "..сбор.." or "ЗАБРАТЬ ВСЕ")
    end)

    -- Сбор почты (OnUpdate)
    local frameTime = CreateFrame("Frame")
    local timeElapsed = 0
    frameTime:HookScript("OnUpdate", function(_, elapsed)
        if not MailFrame:IsVisible() then return end

        timeElapsed = timeElapsed + elapsed
        if timeElapsed <= 0.01 then return end
        timeElapsed = 0

        if not isCollecting then return end

        local x = GetInboxNumItems()
        if x >= 1 then
            local l6 = select(6, GetInboxHeaderInfo(1))
            if tonumber(l6) == 0 then
                AutoLootMailItem(1)
                MailItem1Button:Click()
                OpenMailDeleteButton:Click()
                StaticPopup1Button2:Click()
            end
        else
            isCollecting = false
        end
    end)
end)