-- ============================================================================
-- NSQC4 / Interface / Timer
-- Таймер /nstimer: кнопка T с обратным отсчётом. Модуль "ui_timer".
-- ============================================================================

NSQC4.RegisterModule("ui_timer", function()

    local SOUND_TIMER = "Interface\\AddOns\\NSQC4\\Media\\Sounds\\bip.ogg"

    local tButton
    local timerMinutes = 0
    local timerStart = 0
    local isAlarming = false
    local alarmTicker = 0

    -- ========================================================================
    -- Создание кнопки
    -- ========================================================================
    local function CreateTimerButton()
        if tButton then return end

        tButton = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
        tButton:SetSize(32, 32)
        tButton:EnableMouse(true)
        tButton:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
        tButton:RegisterForDrag("LeftButton")
        tButton:SetMovable(true)
        tButton:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

        tButton:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        tButton:SetBackdropColor(0, 0, 0, 0.8)

        local buttonText = tButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        buttonText:SetText("T")
        buttonText:SetPoint("CENTER", tButton, "CENTER")

        tButton:SetScript("OnDragStart", function(self)
            self:StartMoving()
        end)

        tButton:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local point, _, relativePoint, x, y = self:GetPoint()
            local st = nsDbc4.settings.timer
            st.point = point
            st.relativePoint = relativePoint
            st.x = x
            st.y = y
            st.visible = true
        end)

        tButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("NSQC4 — Таймер", 1, 0.8, 0)
            GameTooltip:AddLine(" ", 1, 1, 1)
            if timerMinutes <= 0 then
                GameTooltip:AddLine("• СТАТУС: ВЫКЛЮЧЕН", 0.5, 0.5, 0.5)
                GameTooltip:AddLine("  ЛКМ: Ввести время и включить", 0.7, 0.7, 0.7)
                GameTooltip:AddLine("  СКМ: Мгновенно выключить таймер", 0.7, 0.7, 0.7)
            else
                local currentTime = GetTime()
                local elapsed = currentTime - timerStart
                local targetSeconds = timerMinutes * 60
                if isAlarming then
                    GameTooltip:AddLine("• СТАТУС: СИГНАЛ", 1, 0.2, 0.2)
                    GameTooltip:AddLine("  Звук проигрывается.", 1, 1, 1)
                    GameTooltip:AddLine("  ПКМ: Сбросить и ждать снова.", 0.7, 0.7, 0.7)
                else
                    local left = math.ceil(targetSeconds - elapsed)
                    if left < 0 then left = 0 end
                    local m = math.floor(left / 60)
                    local s = left % 60
                    GameTooltip:AddLine("• СТАТУС: Ожидание", 0.2, 1, 0.2)
                    GameTooltip:AddLine(string.format("  До сигнала: %d мин %d сек", m, s), 1, 1, 1)
                    GameTooltip:AddLine("  ПКМ: Перезапустить отсчет.", 0.7, 0.7, 0.7)
                end
                GameTooltip:AddLine(" ", 1, 1, 1)
                GameTooltip:AddLine("Интервал: " .. timerMinutes .. " мин", 0.7, 0.7, 0.7)
            end
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine("• ЛКМ: Изменить время (0 = Выкл)", 1, 1, 1)
            GameTooltip:AddLine("• СКМ: Мгновенно выключить таймер", 1, 1, 1)
            GameTooltip:Show()
        end)

        tButton:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

        local editBox = CreateFrame("EditBox", nil, tButton)
        editBox:SetSize(60, 20)
        editBox:SetPoint("LEFT", tButton, "RIGHT", 5, 0)
        editBox:Hide()
        editBox:SetAutoFocus(false)
        editBox:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        editBox:SetBackdropColor(0, 0, 0, 0.8)
        editBox:SetTextColor(1, 1, 1, 1)
        editBox:SetFont(STANDARD_TEXT_FONT, 12)

        editBox:SetScript("OnEnterPressed", function(self)
            local text = self:GetText()
            local num = tonumber(text)
            local st = nsDbc4.settings.timer
            if num and num >= 0 then
                timerMinutes = num
                st.time = timerMinutes
                if timerMinutes > 0 then
                    timerStart = GetTime()
                    isAlarming = false
                    alarmTicker = 0
                else
                    isAlarming = false
                end
            else
                timerMinutes = 0
                st.time = 0
            end
            self:Hide()
        end)

        editBox:SetScript("OnEscapePressed", function(self)
            self:Hide()
        end)

        tButton:SetScript("OnClick", function(self, button)
            if button == "LeftButton" then
                editBox:SetText(timerMinutes or 0)
                editBox:Show()
                editBox:SetFocus()
            elseif button == "RightButton" then
                if timerMinutes > 0 then
                    timerStart = GetTime()
                    isAlarming = false
                    alarmTicker = 0
                end
            elseif button == "MiddleButton" then
                timerMinutes = 0
                nsDbc4.settings.timer.time = 0
                timerStart = 0
                isAlarming = false
                alarmTicker = 0
            end
        end)
    end

    -- ========================================================================
    -- Инициализация: создаём кнопку СРАЗУ (без 5-секундного таймера)
    -- ========================================================================
    local st = nsDbc4.settings.timer
    timerMinutes = st.time or 0
    if timerMinutes > 0 then
        timerStart = GetTime()
        isAlarming = false
        alarmTicker = 0
    else
        timerStart = 0
        isAlarming = false
    end

    CreateTimerButton()

    local point = st.point or "CENTER"
    local relativePoint = st.relativePoint or "CENTER"
    local x = st.x or 0
    local y = st.y or 0

    tButton:ClearAllPoints()
    tButton:SetPoint(point, UIParent, relativePoint, x, y)

    if st.visible then
        tButton:Show()
    else
        tButton:Hide()
    end

    -- ========================================================================
    -- Слэш-команда
    -- ========================================================================
    SLASH_NSTIMER1 = "/nstimer"
    SlashCmdList["NSTIMER"] = function()
        if not tButton then
            local st = nsDbc4.settings.timer
            timerMinutes = st.time or 0
            CreateTimerButton()
            local point = st.point or "CENTER"
            local relativePoint = st.relativePoint or "CENTER"
            local x = st.x or 0
            local y = st.y or 0
            tButton:ClearAllPoints()
            tButton:SetPoint(point, UIParent, relativePoint, x, y)
        end
        local st = nsDbc4.settings.timer
        if tButton:IsShown() then
            tButton:Hide()
            st.visible = false
        else
            tButton:Show()
            st.visible = true
        end
    end

    -- ========================================================================
    -- Основной OnUpdate (отсчёт таймера)
    -- ========================================================================
    local ticker = CreateFrame("Frame")
    ticker:SetScript("OnUpdate", function(self, dt)
        if tButton and GameTooltip:IsVisible() and GameTooltip:GetOwner() == tButton then
            tButton:GetScript("OnEnter")(tButton)
        end

        if timerMinutes <= 0 then return end
        if timerStart == 0 then return end

        local currentTime = GetTime()
        local elapsed = currentTime - timerStart
        local targetSeconds = timerMinutes * 60

        if not isAlarming then
            if elapsed >= targetSeconds then
                isAlarming = true
                PlaySoundFile(SOUND_TIMER)
            end
        else
            alarmTicker = alarmTicker + dt
            if alarmTicker >= 1.0 then
                alarmTicker = 0
                PlaySoundFile(SOUND_TIMER)
            end
        end
    end)
end)