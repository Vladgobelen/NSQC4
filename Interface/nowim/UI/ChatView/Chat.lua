-- ============================================================================
-- NSQC4 / nowim / UI / ChatView
-- Совместимо с WoW 3.3.5 (CircleL)
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

    -- ----- ScrollFrame + content -----
    local scroll = CreateFrame("ScrollFrame", "NSQC4_NowimChatScroll", parent)
    V.Scroll = scroll

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(300, 1)
    scroll:SetScrollChild(content)
    V.Content = content

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

    -- ----- Рисование пузырей -----
    local myName = UnitName("player") or "Unknown"

    local measure = content:CreateFontString(nil, "OVERLAY")
    measure:SetJustifyH("LEFT")
    measure:SetWordWrap(true)
    measure:Hide()

    -- Цвета для разных типов чата
    local CHAT_COLORS = {
        SYSTEM = "|cffffd100", -- Желтый
        GUILD  = "|cff40ff40", -- Зеленый
        OFFICER = "|cff40ff40",-- Зеленый
        RAID   = "|cffff8000", -- Оранжевый
        PARTY  = "|cffaaaaaa", -- Синий (или белый)
        SAY    = "|cffffffff", -- Белый
        YELL   = "|cffff0000", -- Красный
        WHISPER = "|cffff80ff",-- Розовый
        CHANNEL = "|cffaaaaaa",-- Серый
    }

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
            
            -- Определяем префикс отправителя
            local senderPrefix = ""
            local textColor = "|cffffffff" -- По умолчанию белый
            
            if msg.char then
                local senderName = msg.isMine and myName or msg.char
                -- Ищем цвет для этого типа чата в таблице
                local color = CHAT_COLORS[msg.chatType] or (msg.isMine and C.COLOR_MY_MSG or C.COLOR_OTHER_MSG)
                textColor = color
                senderPrefix = color .. senderName .. ":|r "
            elseif msg.isMine then
                senderPrefix = C.COLOR_MY_MSG .. myName .. ":|r "
            end

            -- Собираем финальный текст с цветом
            local fullText = string.format("%s%s%s%s|r", timeStr, senderPrefix, textColor, msg.text)
            
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
                bg:SetVertexColor(0.1, 0.3, 0.1, 0.9) -- Зеленоватый фон для своих
                bubble:SetPoint("TOPRIGHT", content, "TOPRIGHT", -PADDING_RIGHT, -yOffset)
            else
                bg:SetVertexColor(0.2, 0.2, 0.2, 0.9) -- Серый фон для чужих
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