-- ============================================================================
-- NSQC4 / Interface / ChatButtons
-- Кнопки у чат-фреймов: Общение, Вниз, Настройки. Модуль "ui_chat".
-- ============================================================================

NSQC4 = NSQC4 or {}

local function InitModule()
    if not NSQC4.Settings.IsModuleEnabled("ui_chat") then return end

    -- Кэш настроек
    local chatSettings = nsDbc4.settings.chat
    if not chatSettings then
        nsDbc4.settings.chat = { showChatColor = true, openGuildChat = false }
        chatSettings = nsDbc4.settings.chat
    end

    -- ========================================================================
    -- Получить текущий активный чат-фрейм
    -- ========================================================================
    local function GetCurrentChatFrame()
        for i = 1, NUM_CHAT_WINDOWS do
            local tab = _G["ChatFrame"..i.."Tab"]
            local frame = _G["ChatFrame"..i]
            if tab and frame and frame:IsShown() then
                local name = tab:GetName()
                local selectedMiddle = _G[name.."SelectedMiddle"]
                if selectedMiddle and selectedMiddle:IsShown() then
                    return frame
                end
            end
        end
        return ChatFrame1
    end

    -- ========================================================================
    -- Создать кнопки для чат-фрейма
    -- ========================================================================
    local function CreateChatMenuButton(frame)
        if not frame or frame.menuButton then return end

        -- === Кнопка «Общение» ===
        local socialBtn = CreateFrame("Button", nil, frame)
        socialBtn:SetSize(24, 24)
        socialBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, 22)
        socialBtn:EnableMouse(true)
        socialBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
        socialBtn:SetFrameStrata("FULLSCREEN")

        socialBtn:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        socialBtn:SetBackdropColor(0, 0, 0, 1)
        socialBtn:SetBackdropBorderColor(0, 0, 0, 1)

        local socialText = socialBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        socialText:SetPoint("CENTER", socialBtn, "CENTER")
        socialText:SetFont("Fonts\\FRIZQT__.TTF", 12, "THICKOUTLINE")
        socialText:SetTextColor(1, 1, 1, 1)
        socialText:SetText("0")

        local lastChatType = "default"

        local function UpdateSocialCount()
            local _, online = GetNumFriends()
            socialText:SetText(online or 0)
        end

        local function SetTextColor(chatType)
            if not chatSettings.showChatColor then
                socialText:SetTextColor(0, 1, 0, 1)
                return
            end

            if chatType == "guild" then
                socialText:SetTextColor(0, 1, 0, 1)
            elseif chatType == "raid" then
                socialText:SetTextColor(1, 0.5, 0, 1)
            elseif chatType == "party" then
                socialText:SetTextColor(0.3, 0.5, 1, 1)
            else
                socialText:SetTextColor(1, 1, 1, 1)
            end
            lastChatType = chatType
        end

        -- === Кнопка «Меню» (облачко) ===
        local button = CreateFrame("Button", nil, frame)
        button:SetSize(20, 20)
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, -2)
        button:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-Chat-Up")
        button:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-Chat-Down")
        button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        button:SetScript("OnClick", function(_, mouseButton)
            if mouseButton == "LeftButton" then
                ChatFrameMenuButton:Click()
            end
        end)
        button:Hide()

        -- === Кнопка «Вниз» ===
        local downBtn = CreateFrame("Button", nil, frame)
        downBtn:SetSize(20, 20)
        downBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, -24)
        downBtn:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollEnd-Up")
        downBtn:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollEnd-Down")
        downBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        downBtn:SetScript("OnClick", function(_, mouseButton)
            if mouseButton == "LeftButton" then
                local currentFrame = GetCurrentChatFrame()
                if currentFrame then currentFrame:ScrollToBottom() end
            end
        end)
        downBtn:Hide()

        -- === Кнопка «Настройки» ===
        local settingsBtn = CreateFrame("Button", nil, frame)
        settingsBtn:SetSize(20, 20)
        settingsBtn:SetPoint("BOTTOM", socialBtn, "TOP", 0, 2)
        settingsBtn:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
        settingsBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")

        local settingsBtnText = settingsBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        settingsBtnText:SetPoint("CENTER", settingsBtn, "CENTER")
        settingsBtnText:SetFont("Fonts\\FRIZQT__.TTF", 14, "THICKOUTLINE")
        settingsBtnText:SetTextColor(1, 1, 1, 1)
        settingsBtnText:SetText("*")
        settingsBtn:Hide()

        -- === Панель настроек ===
        local settingsPanel = CreateFrame("Frame", nil, UIParent)
        settingsPanel:SetSize(330, 130)
        settingsPanel:SetPoint("CENTER", UIParent, "CENTER")
        settingsPanel:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        settingsPanel:SetBackdropColor(0, 0, 0, 0.8)
        settingsPanel:SetMovable(true)
        settingsPanel:EnableMouse(true)
        settingsPanel:SetClampedToScreen(true)
        settingsPanel:Hide()

        local title = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", settingsPanel, "TOP", 0, -15)
        title:SetText("Настройки чата")

        local closeBtn = CreateFrame("Button", nil, settingsPanel, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", settingsPanel, "TOPRIGHT", -2, -2)

        local guildChatCheckbox = CreateFrame("CheckButton", nil, settingsPanel, "UICheckButtonTemplate")
        guildChatCheckbox:SetPoint("TOPLEFT", settingsPanel, "TOPLEFT", 15, -40)
        guildChatCheckbox:SetSize(26, 26)
        local cbText1 = guildChatCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        cbText1:SetPoint("LEFT", guildChatCheckbox, "RIGHT", 5, 0)
        cbText1:SetText("Открывать гильдчат при входе в игру")

        local colorChatCheckbox = CreateFrame("CheckButton", nil, settingsPanel, "UICheckButtonTemplate")
        colorChatCheckbox:SetPoint("TOPLEFT", guildChatCheckbox, "BOTTOMLEFT", 0, -10)
        colorChatCheckbox:SetSize(26, 26)
        local cbText2 = colorChatCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        cbText2:SetPoint("LEFT", colorChatCheckbox, "RIGHT", 5, 0)
        cbText2:SetText("Отображать текущий чат цветом")

        local function UpdateCheckboxes()
            guildChatCheckbox:SetChecked(chatSettings.openGuildChat)
            colorChatCheckbox:SetChecked(chatSettings.showChatColor)
        end

        guildChatCheckbox:SetScript("OnClick", function(self)
            chatSettings.openGuildChat = self:GetChecked() and true or false
        end)

        colorChatCheckbox:SetScript("OnClick", function(self)
            chatSettings.showChatColor = self:GetChecked() and true or false
            for i = 1, NUM_CHAT_WINDOWS do
                local f = _G["ChatFrame"..i]
                if f and f.socialButton and f.socialButton.UpdateColor then
                    f.socialButton.UpdateColor()
                end
            end
        end)

        settingsPanel:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then self:StartMoving() end
        end)
        settingsPanel:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" then self:StopMovingOrSizing() end
        end)

        local function ToggleSettingsPanel()
            if settingsPanel:IsShown() then
                settingsPanel:Hide()
            else
                UpdateCheckboxes()
                settingsPanel:Show()
            end
        end

        settingsBtn:SetScript("OnClick", function(_, mouseButton)
            if mouseButton == "LeftButton" then ToggleSettingsPanel() end
        end)

        -- === Видимость кнопок ===
        local buttonsVisible = false
        local function ToggleButtons()
            buttonsVisible = not buttonsVisible
            if buttonsVisible then
                button:Show()
                downBtn:Show()
                settingsBtn:Show()
            else
                button:Hide()
                downBtn:Hide()
                settingsBtn:Hide()
            end
        end

        -- === Даблклик ПКМ ===
        local lastRightClickTime = 0
        local rightDoubleClickDetected = false
        local rightClickResetTimer = 0

        socialBtn:SetScript("OnMouseDown", function(_, mouseButton)
            if mouseButton == "RightButton" then
                local currentTime = GetTime()
                if (currentTime - lastRightClickTime) < 0.3 then
                    rightDoubleClickDetected = true
                    rightClickResetTimer = 0
                    local currentFrame = GetCurrentChatFrame()
                    if currentFrame and currentFrame.editBox then
                        currentFrame.editBox:SetText("/с ")
                        currentFrame.editBox:SetFocus()
                        currentFrame.editBox:HighlightText()
                        SetTextColor("say")
                    end
                else
                    rightClickResetTimer = 0.3
                end
                lastRightClickTime = currentTime
            end
        end)

        local timerFrame = CreateFrame("Frame", nil, socialBtn)
        timerFrame:SetScript("OnUpdate", function(_, elapsed)
            if rightClickResetTimer > 0 then
                rightClickResetTimer = rightClickResetTimer - elapsed
                if rightClickResetTimer <= 0 then
                    lastRightClickTime = 0
                    rightClickResetTimer = 0
                end
            end
        end)

        socialBtn:SetScript("OnClick", function(_, mouseButton)
            if rightDoubleClickDetected then
                rightDoubleClickDetected = false
                return
            end

            if mouseButton == "LeftButton" then
                if IsShiftKeyDown() then
                    local currentFrame = GetCurrentChatFrame()
                    if currentFrame and currentFrame.editBox then
                        currentFrame.editBox:SetText("/p ")
                        currentFrame.editBox:SetFocus()
                        currentFrame.editBox:HighlightText()
                        SetTextColor("party")
                    end
                else
                    if FriendsMicroButton then FriendsMicroButton:Click() end
                end
            elseif mouseButton == "RightButton" then
                if IsShiftKeyDown() then
                    local currentFrame = GetCurrentChatFrame()
                    if currentFrame and currentFrame.editBox then
                        currentFrame.editBox:SetText("/ra ")
                        currentFrame.editBox:SetFocus()
                        currentFrame.editBox:HighlightText()
                        SetTextColor("raid")
                    end
                else
                    ToggleButtons()
                end
            elseif mouseButton == "MiddleButton" then
                local currentFrame = GetCurrentChatFrame()
                if currentFrame and currentFrame.editBox then
                    currentFrame.editBox:SetText("/g ")
                    currentFrame.editBox:SetFocus()
                    currentFrame.editBox:HighlightText()
                    SetTextColor("guild")
                end
            end
        end)

        -- === Тултип ===
        socialBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Меню общения", 1, 1, 1)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cff00ff00ЛКМ|r - Список друзей", 0.9, 0.9, 0.9)
            GameTooltip:AddLine("|cff00ff00Shift+ЛКМ|r - Групповой чат |cff8888ff(/p)|r", 0.9, 0.9, 0.9)
            GameTooltip:AddLine("|cff00ff00ПКМ|r - Показать/скрыть меню", 0.9, 0.9, 0.9)
            GameTooltip:AddLine("|cff00ff00Даблклик ПКМ|r - Общий чат |cff8888ff(/с)|r", 0.9, 0.9, 0.9)
            GameTooltip:AddLine("|cff00ff00Shift+ПКМ|r - Рейдовый чат |cff8888ff(/ra)|r", 0.9, 0.9, 0.9)
            GameTooltip:AddLine("|cff00ff00Колесо мыши|r - Гильдчат |cff8888ff(/g)|r", 0.9, 0.9, 0.9)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Цвет текста показывает последний чат:", 1, 0.8, 0)
            GameTooltip:AddLine("|cff00ff00Зеленый|r - Гильдия", 0.9, 0.9, 0.9)
            GameTooltip:AddLine("|cffFF8000Оранжевый|r - Рейд", 0.9, 0.9, 0.9)
            GameTooltip:AddLine("|cff4D80FFСиний|r - Группа", 0.9, 0.9, 0.9)
            GameTooltip:AddLine("|cffFFFFFFБелый|r - Общий", 0.9, 0.9, 0.9)
            GameTooltip:Show()
        end)

        socialBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        -- === Событие FRIENDLIST_UPDATE ===
        local eventFrame = CreateFrame("Frame", nil, socialBtn)
        eventFrame:RegisterEvent("FRIENDLIST_UPDATE")
        eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

        local enterWorldDelay = 0
        local enterWorldCheck = false

        eventFrame:SetScript("OnEvent", function(_, event)
            if event == "FRIENDLIST_UPDATE" then
                UpdateSocialCount()
            elseif event == "PLAYER_ENTERING_WORLD" then
                UpdateSocialCount()
                enterWorldDelay = 3
                enterWorldCheck = true
            end
        end)

        eventFrame:SetScript("OnUpdate", function(_, elapsed)
            if enterWorldCheck then
                enterWorldDelay = enterWorldDelay - elapsed
                if enterWorldDelay <= 0 then
                    enterWorldCheck = false
                    if chatSettings.openGuildChat then
                        local currentFrame = GetCurrentChatFrame()
                        if currentFrame and currentFrame.editBox then
                            currentFrame.editBox:SetText("/g ")
                            currentFrame.editBox:SetFocus()
                            currentFrame.editBox:HighlightText()
                            SetTextColor("guild")
                        end
                    end
                end
            end
        end)

        socialBtn.UpdateColor = function()
            SetTextColor(lastChatType)
        end

        socialBtn:Show()
        UpdateSocialCount()

        frame.socialButton = socialBtn
        frame.menuButton = button
        frame.scrollButton = downBtn
        frame.settingsButton = settingsBtn
        frame.settingsPanel = settingsPanel
    end

    -- Создать для всех чат-фреймов
    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame"..i]
        if frame then CreateChatMenuButton(frame) end
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, addon)
    if addon ~= "NSQC4" then return end
    self:UnregisterEvent("ADDON_LOADED")
    InitModule()
end)