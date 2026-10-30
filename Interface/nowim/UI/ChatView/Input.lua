-- ============================================================================
-- NSQC4 / nowim / UI / Input
-- ============================================================================

NSQC4.RegisterModule("nowim", function()
    local C = NSQC4.Nowim.Config
    local E = NSQC4.Nowim.ChatEngine
    local U = NSQC4.Nowim.Utils
    local UI = NSQC4.Nowim.UI

    local I = {}
    UI.Input = I
    I._opening = false
    local parent = UI.Content

    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(25)
    I.Container = container

    local scroll = CreateFrame("ScrollFrame", nil, container)
    scroll:SetPoint("TOPLEFT", 0, 0)
    scroll:SetPoint("BOTTOMRIGHT", 0, 0)

    local editBox = CreateFrame("EditBox", nil, scroll)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetTextColor(1, 1, 1, 1)
    editBox:SetWidth(100)
    editBox:SetHeight(20)
    scroll:SetScrollChild(editBox)
    I.EditBox = editBox

    local counter = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    counter:SetPoint("BOTTOMRIGHT", -5, 5)
    counter:SetTextColor(0.5, 0.5, 0.5)

    local function IsIdleHidden()
        if I._opening then return false end
        if C.db.settings.showInputIdle then return false end
        return not editBox:HasFocus()
    end

    local function GetInputHeight()
        if IsIdleHidden() then return 0 end
        local K = UI.Const or {}
        local minH = K.INPUT_HEIGHT or 30
        local text = editBox:GetText() or ""
        local lines = 1
        for _ in text:gmatch("\n") do lines = lines + 1 end
        local h = math.min(5, lines) * 16 + 10
        if h < minH then h = minH end
        return h
    end

    local function ApplyContainerSize()
        local h = GetInputHeight()
        container:SetHeight(h)
        if h > 0 then
            container:Show()
            editBox:Show()
            local w = container:GetWidth()
            if not w or w < 20 then w = 200 end
            editBox:SetWidth(w - 10)
        else
            container:Hide()
        end
        if UI.Chat and UI.Chat.OnResize then UI.Chat.OnResize() end
    end

    local ticker = CreateFrame("Frame")
    ticker:Hide()
    ticker:SetScript("OnUpdate", function(self)
        self:Hide()
        editBox:SetFocus()
        I._opening = false
        ApplyContainerSize()
    end)

    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    editBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText() or ""
        local bytes = #text
        counter:SetText(bytes .. "/" .. C.MAX_BYTES)
        counter:SetTextColor(bytes > C.MAX_BYTES and 1 or 0.5, bytes > C.MAX_BYTES and 0 or 0.5, 0.5)
        ApplyContainerSize()
    end)

    editBox:SetScript("OnEnterPressed", function(self)
        if IsShiftKeyDown() then
            self:Insert("\n")
        else
            local text = self:GetText()
            if text and text:match("%S") then
                -- Если это команда, отправляем как единую строку
                if text:sub(1, 1) == "/" then
                    E.SendMessage(text)
                else
                    -- Обычный текст разбиваем по строкам
                    for line in text:gmatch("[^\r\n]+") do
                        E.SendMessage(U.TrimToBytes(line:trim(), C.MAX_BYTES))
                    end
                end
            end
            self:SetText("")
            self:ClearFocus()
        end
    end)

    editBox:SetScript("OnEditFocusGained", function()
        ApplyContainerSize()
    end)

    editBox:SetScript("OnEditFocusLost", function()
        ApplyContainerSize()
    end)

    function I.Open()
        I._opening = true
        container:Show()
        editBox:Show()

        local w = container:GetWidth()
        if not w or w < 20 then w = 200 end
        editBox:SetWidth(w - 10)

        container:SetHeight((UI.Const and UI.Const.INPUT_HEIGHT) or 30)

        ticker:Show()
    end

    function I.OnResize()
        local K = UI.Const or {}
        local leftOpen  = UI.LeftPanel  and UI.LeftPanel.IsOpen
        local rightOpen = UI.RightPanel and UI.RightPanel.IsOpen
        local left  = leftOpen  and (K.LEFT_WIDTH  or 140) or 0
        local right = rightOpen and (K.RIGHT_WIDTH or 36)  or 0

        container:ClearAllPoints()
        container:SetPoint("BOTTOMLEFT", left + 2, 2)
        container:SetPoint("BOTTOMRIGHT", -right - 2, 2)

        local h = GetInputHeight()
        container:SetHeight(h)
        if h > 0 then
            container:Show()
            editBox:Show()
        else
            container:Hide()
        end
        editBox:SetWidth(container:GetWidth() - 10)
    end

    container:SetScript("OnSizeChanged", function()
        local w = container:GetWidth()
        if w and w > 20 then
            editBox:SetWidth(w - 10)
        end
    end)

    I.OnResize()
end)