-- ============================================================================
-- NSQC4 / Interface / ui_frames / Chat
-- Фильтрация чата по тексту и каналам. Модуль "ui_frames_chat".
-- ============================================================================

NSQC4.RegisterModule("ui_frames_chat", function()

    -- ========================================================================
    -- Хранилище: nsDbc4.settings.framesChat
    -- ========================================================================
    nsDbc4.settings.framesChat = nsDbc4.settings.framesChat or {
        filters = {},
        captureDelay = 5,
    }
    local db = nsDbc4.settings.framesChat
    db.filters = db.filters or {}

    -- ========================================================================
    -- Список доступных каналов
    -- ========================================================================
    local CHANNELS = {
        { name = "Офицерский", event = "CHAT_MSG_OFFICER" },
        { name = "Гильдия",    event = "CHAT_MSG_GUILD" },
        { name = "Группа",     event = "CHAT_MSG_PARTY" },
        { name = "Рейд",       event = "CHAT_MSG_RAID" },
        { name = "Рейд лидер", event = "CHAT_MSG_RAID_LEADER" },
        { name = "Общий",      event = "CHAT_MSG_SAY" },
        { name = "Крик",       event = "CHAT_MSG_YELL" },
        { name = "Шепот",      event = "CHAT_MSG_WHISPER" },
        { name = "Каналы",     event = "CHAT_MSG_CHANNEL" },
    }

    -- ========================================================================
    -- Утилиты
    -- ========================================================================
    local function SafeLower(text)
        if type(text) ~= "string" then return "" end
        if type(string.utf8lower) == "function" then
            return string.utf8lower(text)
        end
        return string.lower(text)
    end

    -- ========================================================================
    -- Фильтрация
    -- ========================================================================
    local function FilterMessage(_, event, msg)
        if type(msg) ~= "string" or msg == "" then return false end
        local lowerMsg = SafeLower(msg)

        for _, filterData in ipairs(db.filters) do
            if type(filterData) == "table"
                and type(filterData.text) == "string"
                and filterData.text ~= ""
                and type(filterData.channels) == "table"
                and filterData.channels[event]
            then
                if string.find(lowerMsg, SafeLower(filterData.text), 1, true) then
                    return true
                end
            end
        end
        return false
    end

    -- Регистрация фильтров для всех каналов
    if ChatFrame_AddMessageEventFilter then
        for _, ch in ipairs(CHANNELS) do
            ChatFrame_AddMessageEventFilter(ch.event, FilterMessage)
        end
    end

    -- ========================================================================
    -- Окно выбора каналов
    -- ========================================================================
    local channelFrame
    local checkboxes = {}
    local filterTextForChannel = ""

    local function CreateChannelFrame()
        if channelFrame then return channelFrame end

        local f = CreateFrame("Frame", "NSQC4FramesChatChannels", UIParent)
        f:SetSize(280, 340)
        f:SetPoint("CENTER")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        f:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then self:StartMoving() end
        end)
        f:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" then self:StopMovingOrSizing() end
        end)
        f:Hide()

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -15)
        title:SetText("Выберите каналы")

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -5, -5)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        checkboxes = {}
        for i, ch in ipairs(CHANNELS) do
            local cb = CreateFrame("CheckButton", nil, f, "ChatConfigCheckButtonTemplate")
            cb:SetPoint("TOPLEFT", 20, -45 - ((i - 1) * 25))
            cb:SetChecked(false)

            local cbText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            cbText:SetPoint("LEFT", cb, "RIGHT", 5, 0)
            cbText:SetText(ch.name)

            checkboxes[ch.event] = cb
        end

        local saveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        saveBtn:SetSize(100, 22)
        saveBtn:SetPoint("BOTTOM", 0, 15)
        saveBtn:SetText("Добавить")
        saveBtn:SetScript("OnClick", function()
            local channels = {}
            for _, ch in ipairs(CHANNELS) do
                if checkboxes[ch.event]:GetChecked() then
                    channels[ch.event] = true
                end
            end

            if filterTextForChannel ~= "" then
                local lowerText = SafeLower(filterTextForChannel)
                local duplicate = false

                for _, fd in ipairs(db.filters) do
                    if type(fd) == "table" and SafeLower(fd.text or "") == lowerText then
                        duplicate = true
                        break
                    end
                end

                if not duplicate then
                    table.insert(db.filters, {
                        text = filterTextForChannel,
                        channels = channels,
                    })
                end

                if NSQC4.FramesChat_RefreshList then
                    NSQC4.FramesChat_RefreshList()
                end
            end

            channelFrame:Hide()
        end)

        channelFrame = f
        return f
    end

    local function OpenChannelSelect()
        local f = NSQC4FramesChatFrame
        if not f or not f.input then return end

        local rawText = f.input:GetText()
        if not rawText then return end

        local text = rawText:match("^%s*(.-)%s*$")
        if not text or text == "" then return end

        filterTextForChannel = text

        local cf = CreateChannelFrame()
        for _, ch in ipairs(CHANNELS) do
            checkboxes[ch.event]:SetChecked(false)
        end
        cf:Raise()
        cf:Show()
    end

    -- ========================================================================
    -- Главное окно модуля
    -- ========================================================================
    local mainFrame

    local function CreateMainFrame()
        if mainFrame then return mainFrame end

        local f = CreateFrame("Frame", "NSQC4FramesChatFrame", UIParent)
        f:SetSize(480, 420)
        f:SetPoint("CENTER")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:SetFrameStrata("DIALOG")
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        f:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then self:StartMoving() end
        end)
        f:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" then self:StopMovingOrSizing() end
        end)
        f:Hide()

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -15)
        title:SetText("Фильтрация чата")

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -5, -5)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        -- Поле ввода
        local input = CreateFrame("EditBox", "NSQC4FramesChatInput", f, "InputBoxTemplate")
        input:SetSize(350, 20)
        input:SetPoint("TOPLEFT", 20, -45)
        input:SetMaxLetters(255)
        input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        input:SetScript("OnEnterPressed", function() OpenChannelSelect() end)
        f.input = input

        -- Кнопка +
        local addBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        addBtn:SetSize(30, 20)
        addBtn:SetPoint("LEFT", input, "RIGHT", 5, 0)
        addBtn:SetText("+")
        addBtn:SetScript("OnClick", function() OpenChannelSelect() end)

        -- Скролл
        local scroll = CreateFrame("ScrollFrame", "NSQC4FramesChatScroll", f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 20, -75)
        scroll:SetPoint("BOTTOMRIGHT", -40, 45)
        f.scroll = scroll

        local child = CreateFrame("Frame", "NSQC4FramesChatList", scroll)
        child:SetSize(400, 10)
        scroll:SetScrollChild(child)
        f.list = child

        -- Кнопка «Очистить всё»
        local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        clearBtn:SetSize(140, 22)
        clearBtn:SetPoint("BOTTOM", 0, 15)
        clearBtn:SetText("Очистить всё")
        clearBtn:SetScript("OnClick", function()
            db.filters = {}
            if NSQC4.FramesChat_RefreshList then
                NSQC4.FramesChat_RefreshList()
            end
        end)

        mainFrame = f
        return f
    end

    -- ========================================================================
    -- Список фильтров
    -- ========================================================================
    local function GetChannelsString(channels)
        if type(channels) ~= "table" then return "Все каналы" end

        local names = {}
        for _, ch in ipairs(CHANNELS) do
            if channels[ch.event] then
                table.insert(names, ch.name)
            end
        end

        if #names == 0 then return "Нет каналов"
        elseif #names == #CHANNELS then return "Все каналы"
        else return table.concat(names, ", ") end
    end

    function NSQC4.FramesChat_RefreshList()
        local f = mainFrame
        if not f or not f.list then return end

        local child = f.list
        local scroll = f.scroll

        for _, c in ipairs({ child:GetChildren() }) do
            c:Hide()
        end

        local ENTRY_H = 25
        local count = #db.filters
        child:SetHeight(math.max(count * ENTRY_H, 10))

        for i, fd in ipairs(db.filters) do
            if type(fd) == "table" and type(fd.text) == "string" then
                local row = CreateFrame("Frame", nil, child)
                row:SetWidth(400)
                row:SetHeight(ENTRY_H)
                row:SetPoint("TOPLEFT", 0, -((i - 1) * ENTRY_H))
                row:EnableMouse(true)

                local txt = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                txt:SetPoint("LEFT", 5, 0)
                txt:SetWidth(340)
                txt:SetJustifyH("LEFT")
                txt:SetText(fd.text)

                local rem = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                rem:SetSize(25, 20)
                rem:SetPoint("RIGHT", -5, 0)
                rem:SetText("-")
                rem:SetScript("OnClick", function()
                    table.remove(db.filters, i)
                    NSQC4.FramesChat_RefreshList()
                end)

                row:SetScript("OnEnter", function()
                    txt:SetTextColor(1, 1, 0)
                    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                    GameTooltip:SetText("Фильтр: " .. fd.text, 1, 1, 1)
                    GameTooltip:AddLine("Каналы: " .. GetChannelsString(fd.channels), 0, 1, 0, true)
                    GameTooltip:Show()
                end)
                row:SetScript("OnLeave", function()
                    txt:SetTextColor(1, 1, 1)
                    GameTooltip:Hide()
                end)
            end
        end

        scroll:UpdateScrollChildRect()
    end

    -- ========================================================================
    -- Слэш-команда /ns_fc
    -- ========================================================================
    SLASH_NS_FC1 = "/ns_fc"
    SlashCmdList["NS_FC"] = function()
        local f = CreateMainFrame()
        if f:IsShown() then
            f:Hide()
        else
            f:Raise()
            f:Show()
            NSQC4.FramesChat_RefreshList()
        end
    end

    -- ========================================================================
    -- Регистрация кнопки на панели
    -- ========================================================================
    if NSQC4.SlashPanel_RegisterButton then
        NSQC4.SlashPanel_RegisterButton("FC", "/ns_fc", "Фильтрация чата", function()
            SlashCmdList["NS_FC"]("")
        end)
    end

end)