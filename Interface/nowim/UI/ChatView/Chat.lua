-- ============================================================================
-- NSQC4 / nowim / UI / ChatView
-- ============================================================================

NSQC4.RegisterModule("nowim", function()
    local C = NSQC4.Nowim.Config
    local S = NSQC4.Nowim.Storage
    local UI = NSQC4.Nowim.UI
    local K = UI.Const or {}

    local V = {}
    UI.ChatView = V
    UI.Chat = V
    local parent = UI.Content

    local scroll = CreateFrame("ScrollFrame", "NSQC4_NowimChatScroll", parent)
    V.Scroll = scroll

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(300, 1)
    scroll:SetScrollChild(content)
    V.Content = content

    -- ЛОВУШКА ДЛЯ КЛИКОВ: запоминает фокус на Nowim и открывает ввод
    local clickCatcher = CreateFrame("Frame", nil, parent)
    clickCatcher:SetAllPoints(scroll)
    clickCatcher:EnableMouse(true)
    clickCatcher:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then return end
        if NSQC4.Nowim.FocusNowimChat then
            NSQC4.Nowim.FocusNowimChat()
        end
        if UI.Input and UI.Input.Open then
            UI.Input.Open()
        end
    end)

    local scrollBar = CreateFrame("Slider", "NSQC4_NowimChatScrollBar", parent)
    scrollBar:SetWidth(8)
    scrollBar:SetMinMaxValues(0, 0)
    scrollBar:SetValueStep(1)
    scrollBar:SetAlpha(0.01)

    local thumb = scrollBar:CreateTexture(nil, "ARTWORK")
    thumb:SetTexture("Interface\\Buttons\\WHITE8x8")
    thumb:SetSize(8, 30)
    thumb:SetVertexColor(0.6, 0.6, 0.6, 1)
    scrollBar:SetThumbTexture(thumb)

    scrollBar:EnableMouse(true)
    scrollBar:SetScript("OnEnter", function(self) self:SetAlpha(1) end)
    scrollBar:SetScript("OnLeave", function(self)
        if not scroll:IsMouseOver() then self:SetAlpha(0.01) end
    end)
    scrollBar:SetScript("OnValueChanged", function(self, value)
        scroll:SetVerticalScroll(value)
    end)
    V.ScrollBar = scrollBar

    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local offset = scroll:GetVerticalScroll() or 0
        local maxScroll = math.max(0, (content:GetHeight() or 0) - (scroll:GetHeight() or 0))
        local newOffset = math.max(0, math.min(offset - (delta * 30), maxScroll))
        scroll:SetVerticalScroll(newOffset)
        scrollBar:SetValue(newOffset)
    end)
    scroll:SetScript("OnVerticalScroll", function(self, offset)
        content:ClearAllPoints()
        content:SetPoint("TOPLEFT", self, "TOPLEFT", 0, offset)
    end)

    function V.ScrollToBottom()
        local maxScroll = math.max(0, (content:GetHeight() or 0) - (scroll:GetHeight() or 0))
        scroll:SetVerticalScroll(maxScroll)
        scrollBar:SetValue(maxScroll)
        scrollBar:SetMinMaxValues(0, maxScroll)
    end

    local myName = UnitName("player") or "Unknown"

    local measure = content:CreateFontString(nil, "OVERLAY")
    measure:SetJustifyH("LEFT")
    measure:SetWordWrap(true)
    measure:Hide()

    function V.Refresh()
        local active = C.db.activeTab
        if not active then
            content:SetHeight(1)
            return
        end

        local messages = S.GetMessages(active)
        if not messages or #messages == 0 then
            content:SetHeight(1)
            V.ScrollToBottom()
            return
        end

        for _, child in ipairs({content:GetChildren()}) do
            if child ~= measure then
                child:Hide()
                child:SetParent(nil)
            end
        end

        local KK = UI.Const or K
        local BUBBLE_PADDING = (KK.BUBBLE_PADDING or 6) + 2
        local GAP            = KK.GAP or 6
        local PADDING_LEFT   = KK.CHAT_PADDING_L or 0
        local PADDING_RIGHT  = KK.CHAT_PADDING_R or 0
        local PADDING_TOP    = 8

        local yOffset = PADDING_TOP
        local totalWidth = scroll:GetWidth()
        if totalWidth < 50 then totalWidth = 300 end

        local maxBubbleWidth = totalWidth - PADDING_LEFT - PADDING_RIGHT
        content:SetWidth(totalWidth)

        local fontPath = "Fonts\\FRIZQT__.TTF"
        local fontSize = C.db.settings.fontSize or 12

        measure:SetFont(fontPath, fontSize)
        measure:SetWordWrap(true)
        measure:SetNonSpaceWrap(true)

        for _, msg in ipairs(messages) do
            local timeStr = C.COLOR_TIME .. "[" .. msg.time .. "]|r "

            local textColor = "|cffffffff"
            if msg.chatType == "SYSTEM" or msg.chatType == "LOOT" or msg.chatType == "MONEY" or msg.chatType == "SKILL" then
                textColor = "|cffffd100"
            elseif msg.isMine then
                textColor = C.COLOR_MY_MSG
            else
                textColor = C.COLOR_OTHER_MSG
            end

            local isAO = msg.text and (msg.text:find("^%[О") or msg.text:find("^%[А") or msg.text:find("^%[O") or msg.text:find("^%[A") or msg.text:find("^|c%x%x%x%x%x%x%[О") or msg.text:find("^|c%x%x%x%x%x%x%[А") or msg.text:find("^|c%x%x%x%x%x%x%[O") or msg.text:find("^|c%x%x%x%x%x%x%[A"))

            local senderPrefix = ""
            if not isAO and not msg.isMine and msg.char then
                senderPrefix = textColor .. msg.char .. ":|r "
            end

            local displayText = msg.text or ""

            if isAO then
                local factionLetter = ""
                if displayText:find("^%[О") or displayText:find("^|c%x%x%x%x%x%x%[О") then factionLetter = "О"
                elseif displayText:find("^%[А") or displayText:find("^|c%x%x%x%x%x%x%[А") then factionLetter = "А"
                elseif displayText:find("^%[O") or displayText:find("^|c%x%x%x%x%x%x%[O") then factionLetter = "О"
                elseif displayText:find("^%[A") or displayText:find("^|c%x%x%x%x%x%x%[A") then factionLetter = "А"
                end

                local channelLetter = (active == "OFFICER") and "O" or "G"
                local prefix = "[" .. channelLetter .. factionLetter .. "] "

                displayText = prefix .. displayText

                if NSQC4.AOClick_ReplaceAll then
                    displayText = NSQC4.AOClick_ReplaceAll(displayText)
                end

                displayText = textColor .. displayText .. "|r"
            else
                displayText = textColor .. displayText .. "|r"
            end

            local fullText = string.format("%s%s%s", timeStr, senderPrefix, displayText)

            local maxTextW = maxBubbleWidth - (BUBBLE_PADDING * 2)

            measure:SetWidth(0)
            measure:SetText(fullText)
            local measuredW = measure:GetStringWidth() or 100

            local finalTextW = math.max(40, measuredW)
            if finalTextW > maxTextW then finalTextW = maxTextW end

            measure:SetWidth(finalTextW)
            measure:SetText(fullText)
            local textHeight = measure:GetStringHeight() or (fontSize + 4)

            local bubble = CreateFrame("Frame", nil, content)
            bubble:SetSize(finalTextW + (BUBBLE_PADDING * 2), textHeight + (BUBBLE_PADDING * 2))

            local bg = bubble:CreateTexture(nil, "BACKGROUND")
            bg:SetTexture("Interface\\Buttons\\WHITE8x8")
            bg:SetAllPoints(bubble)

            if msg.isMine then
                bg:SetVertexColor(0.1, 0.3, 0.1, 0.9)
                bubble:SetPoint("TOPRIGHT", content, "TOPRIGHT", -PADDING_RIGHT, -yOffset)
            else
                bg:SetVertexColor(0.2, 0.2, 0.2, 0.9)
                bubble:SetPoint("TOPLEFT", content, "TOPLEFT", PADDING_LEFT, -yOffset)
            end

            local textStr = bubble:CreateFontString(nil, "OVERLAY")
            textStr:SetFont(fontPath, fontSize)
            textStr:SetJustifyH("LEFT")
            textStr:SetWordWrap(true)
            textStr:SetNonSpaceWrap(true)
            textStr:SetPoint("TOPLEFT", bubble, "TOPLEFT", BUBBLE_PADDING, -BUBBLE_PADDING)
            textStr:SetWidth(finalTextW)
            textStr:SetText(fullText)

            yOffset = yOffset + bubble:GetHeight() + GAP
        end

        content:SetHeight(math.max(1, yOffset + PADDING_TOP))
        scroll:UpdateScrollChildRect()
        V.ScrollToBottom()
    end

    function V.OnResize()
        local KK = UI.Const or K
        local gap = KK.CHAT_RIGHT_PAD or 20

        local leftOpen  = UI.LeftPanel  and UI.LeftPanel.IsOpen
        local rightOpen = UI.RightPanel and UI.RightPanel.IsOpen

        local panelPad = KK.CHAT_PAD_PANEL or 0

        local left  = leftOpen  and ((KK.LEFT_WIDTH  or 150) + panelPad) or 0
        local right = rightOpen and ((KK.RIGHT_WIDTH or 38)  + gap + panelPad) or gap

        scroll:ClearAllPoints()
        scroll:SetPoint("TOPLEFT", left, -(KK.CHAT_PAD_TOP or 4))

        local inputH = (UI.Input and UI.Input.Container and UI.Input.Container:GetHeight()) or 30
        scroll:SetPoint("BOTTOMRIGHT", -right, inputH + (KK.CHAT_PAD_BOTTOM or 4))

        scrollBar:ClearAllPoints()
        scrollBar:SetPoint("TOPRIGHT", scroll, "TOPRIGHT", 0, -4)
        scrollBar:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", 0, 4)

        V.Refresh()
    end

    V.OnResize()
end)