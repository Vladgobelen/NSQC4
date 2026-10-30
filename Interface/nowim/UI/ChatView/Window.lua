-- ============================================================================
-- NSQC4 / nowim / UI / Window
-- ============================================================================

NSQC4.RegisterModule("nowim", function()
    local C = NSQC4.Nowim.Config
    local S = NSQC4.Nowim.Storage
    local E = NSQC4.Nowim.ChatEngine
    local UI = NSQC4.Nowim.UI or {}
    NSQC4.Nowim.UI = UI

    local K = UI.Const or {}

    local mainFrame = CreateFrame("Frame", "NSQC4_NowimMainFrame", UIParent)
    UI.MainFrame = mainFrame

    mainFrame:SetSize(C.db.window.w or 500, C.db.window.h or 450)
    mainFrame:SetPoint(C.db.window.point or "CENTER", UIParent, C.db.window.relPoint or "CENTER", C.db.window.x or 0, C.db.window.y or 0)
    mainFrame:SetFrameStrata("DIALOG")
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:SetClampedToScreen(true)
    mainFrame:Hide()

    mainFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    mainFrame:SetBackdropColor(0, 0, 0, 0.95)
    mainFrame:SetBackdropBorderColor(1, 1, 1, 1)

    local function ApplyBorder()
        if C.db.settings.showBorder then
            mainFrame:SetBackdropBorderColor(1, 1, 1, 1)
        else
            mainFrame:SetBackdropBorderColor(0, 0, 0, 0)
        end
    end
    ApplyBorder()

    local header = CreateFrame("Frame", nil, mainFrame)
    header:SetPoint("TOPLEFT", 30, 0)
    header:SetPoint("TOPRIGHT", -60, 0)
    header:SetHeight(30)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() mainFrame:StartMoving() end)
    header:SetScript("OnDragStop", function()
        mainFrame:StopMovingOrSizing()
        local p, _, rp, x, y = mainFrame:GetPoint()
        C.db.window.point = p; C.db.window.relPoint = rp; C.db.window.x = x; C.db.window.y = y
    end)

    local closeBtn = CreateFrame("Button", "NSQC4_NowimCloseBtn", mainFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -2, -2)
    closeBtn:SetAlpha(K.BTN_ALPHA or 0.01)
    closeBtn:SetFrameLevel(mainFrame:GetFrameLevel() + 60) -- Поднимаем крестик
    closeBtn:SetScript("OnEnter", function(self) self:SetAlpha(1) end)
    closeBtn:SetScript("OnLeave", function(self) 
        if not NSQC4.Nowim.settingsOpen then self:SetAlpha(K.BTN_ALPHA or 0.01) end 
    end)
    closeBtn:SetScript("OnClick", function() mainFrame:Hide() end)

    local content = CreateFrame("Frame", nil, mainFrame)
    content:SetPoint("TOPLEFT", K.EDGE_PADDING or 4, -(K.EDGE_PADDING or 4))
    content:SetPoint("BOTTOMRIGHT", -(K.EDGE_PADDING or 4), K.EDGE_PADDING or 4)
    UI.Content = content

    local grip = CreateFrame("Button", nil, mainFrame)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -2, 2)
    grip:SetFrameLevel(mainFrame:GetFrameLevel() + 20)
    local gripTex = grip:CreateTexture(nil, "ARTWORK")
    gripTex:SetAllPoints(grip)
    gripTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

    local isResizing = false
    local function StopResize()
        if not isResizing then return end
        isResizing = false
        gripTex:SetVertexColor(1, 1, 1, 1)
        C.db.window.w, C.db.window.h = mainFrame:GetWidth(), mainFrame:GetHeight()
        if UI.ReapplyLayout then UI.ReapplyLayout() end
    end

    grip:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then return end
        isResizing = true
        gripTex:SetVertexColor(0, 1, 1, 1)
        local scale = mainFrame:GetEffectiveScale()
        local cx, cy = GetCursorPosition()
        self._startW, self._startH = mainFrame:GetWidth(), mainFrame:GetHeight()
        self._startX, self._startY = cx / scale, cy / scale
    end)
    grip:SetScript("OnUpdate", function(self)
        if not isResizing then return end
        if not IsMouseButtonDown("LeftButton") then StopResize() return end
        local scale = mainFrame:GetEffectiveScale()
        local cx, cy = GetCursorPosition()
        local dw = (cx / scale) - self._startX
        local dh = (cy / scale) - self._startY
        mainFrame:SetSize(math.max(C.MIN_W, self._startW + dw), math.max(C.MIN_H, self._startH - dh))
    end)
    grip:SetScript("OnMouseUp", function(_, btn) if btn == "LeftButton" then StopResize() end end)
    grip:SetScript("OnHide", StopResize)

    local Tabs = {}
    UI.Tabs = Tabs
    local tabContainer = CreateFrame("Frame", nil, mainFrame)
    tabContainer:SetPoint("BOTTOMLEFT", mainFrame, "TOPLEFT", 30, 0)
    tabContainer:SetPoint("BOTTOMRIGHT", mainFrame, "TOPRIGHT", -30, 0)
    tabContainer:SetHeight(K.TAB_HEIGHT or 24)
    tabContainer:SetFrameLevel(mainFrame:GetFrameLevel() + 10)

    local tabButtons = {}
    local function GetTabLetter(key)
        if key == "GUILD" then return "Г" end
        if key == "OFFICER" then return "О" end
        if key == "RAID" then return "Р" end
        if type(key) ~= "string" then return "?" end
        return (key:match("^([%z\1-\127\194-\244][\128-\191]*)") or "?"):upper()
    end

    function Tabs.Refresh()
        local tabW = (UI.Const and UI.Const.TAB_WIDTH) or K.TAB_WIDTH or 30
        local tabH = (UI.Const and UI.Const.TAB_HEIGHT) or K.TAB_HEIGHT or 24
        tabContainer:SetHeight(tabH)

        for _, btn in pairs(tabButtons) do btn:Hide() end

        local xOffset = 0
        for _, key in ipairs(C.db.openTabs or {}) do
            if type(key) == "string" then
                local btn = tabButtons[key]
                if not btn then
                    btn = CreateFrame("Button", nil, tabContainer)
                    btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 8, insets = {left=2,right=2,top=2,bottom=0} })
                    local t = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                    t:SetPoint("CENTER", 0, 2)
                    t:SetText(GetTabLetter(key))
                    btn:SetScript("OnClick", function() E.OpenDialog(key) end)
                    tabButtons[key] = btn
                end
                btn:SetSize(tabW, tabH)
                btn:ClearAllPoints()
                btn:SetPoint("BOTTOMLEFT", tabContainer, "BOTTOMLEFT", xOffset, 0)
                btn:Show()
                if key == C.db.activeTab then
                    btn:SetBackdropColor(0.1, 0.1, 0.1, 1)
                    btn:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
                else
                    btn:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
                    btn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
                end
                xOffset = xOffset + tabW + 2
            end
        end
    end

    -- ЛЕВАЯ ПАНЕЛЬ
    local LeftPanel = {}
    UI.LeftPanel = LeftPanel
    LeftPanel.IsOpen = false

    local lpFrame = CreateFrame("Frame", nil, mainFrame)
    lpFrame:SetPoint("TOPLEFT", 0, -(K.PANEL_HEIGHT or 20))
    lpFrame:SetPoint("BOTTOMLEFT", 0, 0)
    lpFrame:SetWidth(K.LEFT_WIDTH or 140)
    lpFrame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    lpFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    lpFrame:SetFrameLevel(mainFrame:GetFrameLevel() + 5)
    lpFrame:Hide()
    LeftPanel.Frame = lpFrame

    local lpScroll = CreateFrame("ScrollFrame", "NSQC4_NowimLeftScroll", lpFrame, "UIPanelScrollFrameTemplate")
    lpScroll:SetPoint("TOPLEFT", 5, -5)
    lpScroll:SetPoint("BOTTOMRIGHT", -25, 5)
    local lpContent = CreateFrame("Frame", nil, lpScroll)
    lpContent:SetSize(100, 1)
    lpScroll:SetScrollChild(lpContent)
    LeftPanel.Scroll = lpScroll
    LeftPanel.Content = lpContent
    LeftPanel.Rows = {}

    local lpToggle = CreateFrame("Button", "NSQC4_NowimLeftToggle", mainFrame, "UIPanelButtonTemplate")
    lpToggle:SetSize(20, 20)
    lpToggle:SetText("<")
    lpToggle:SetAlpha(K.BTN_ALPHA or 0.01)
    lpToggle:SetFrameLevel(mainFrame:GetFrameLevel() + 50) -- Поверх окна
    lpToggle:EnableMouse(true) -- ВАЖНО: чтобы клик срабатывал
    lpToggle:SetScript("OnEnter", function(self) self:SetAlpha(1) end)
    lpToggle:SetScript("OnLeave", function(self) 
        if not NSQC4.Nowim.settingsOpen then self:SetAlpha(K.BTN_ALPHA or 0.01) end 
    end)

    local function UpdateLeftTogglePosition()
        local KK = UI.Const or K
        local w = KK.LEFT_WIDTH or 140
        lpToggle:ClearAllPoints()
        if LeftPanel.IsOpen then
            lpToggle:SetPoint("BOTTOMLEFT", mainFrame, "TOPLEFT", w + 2, 0)
        else
            lpToggle:SetPoint("BOTTOMLEFT", mainFrame, "TOPLEFT", 2, 0)
        end
    end

    function LeftPanel.Toggle()
        LeftPanel.IsOpen = not LeftPanel.IsOpen
        if LeftPanel.IsOpen then lpFrame:Show() else lpFrame:Hide() end
        lpToggle:SetText(LeftPanel.IsOpen and ">" or "<")
        UpdateLeftTogglePosition()
        if UI.ReapplyLayout then UI.ReapplyLayout() end
    end
    lpToggle:SetScript("OnClick", LeftPanel.Toggle)

    function LeftPanel.Refresh()
        for _, row in ipairs(LeftPanel.Rows) do
            row:Hide()
            row:SetParent(nil)
        end
        LeftPanel.Rows = {}

        local contacts = S.GetContacts()
        local rowH = 20
        local rowGap = 2
        local yOffset = 0

        for _, contact in ipairs(contacts) do
            local btn = CreateFrame("Button", nil, lpContent)
            btn:SetSize(100, rowH)
            btn:SetPoint("TOPLEFT", 0, -yOffset)
            btn:SetFrameLevel(lpContent:GetFrameLevel() + 2)

            local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            text:SetPoint("LEFT", 2, 0)
            text:SetText(contact.name)

            if C.db.activeTab == contact.key then
                text:SetTextColor(0, 1, 1)
            else
                text:SetTextColor(1, 1, 1)
            end

            btn:SetScript("OnClick", function()
                E.OpenDialog(contact.key)
                if LeftPanel.IsOpen then LeftPanel.Toggle() end
            end)

            table.insert(LeftPanel.Rows, btn)
            yOffset = yOffset + rowH + rowGap
        end
        lpContent:SetHeight(math.max(1, yOffset))
    end

    -- ПРАВАЯ ПАНЕЛЬ
    local RightPanel = {}
    UI.RightPanel = RightPanel
    RightPanel.IsOpen = false

    local rpFrame = CreateFrame("Frame", nil, mainFrame)
    rpFrame:SetPoint("TOPRIGHT", 0, -(K.PANEL_HEIGHT or 20))
    rpFrame:SetPoint("BOTTOMRIGHT", 0, 0)
    rpFrame:SetWidth(K.RIGHT_WIDTH or 36)
    rpFrame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    rpFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    rpFrame:SetFrameLevel(mainFrame:GetFrameLevel() + 5)
    rpFrame:Hide()
    RightPanel.Frame = rpFrame

    local rpToggle = CreateFrame("Button", "NSQC4_NowimRightToggle", mainFrame, "UIPanelButtonTemplate")
    rpToggle:SetSize(20, 20)
    rpToggle:SetText(">")
    
    rpToggle:SetPoint("BOTTOMRIGHT", mainFrame, "TOPRIGHT", -28, 0)
    rpToggle:SetAlpha(K.BTN_ALPHA or 0.01)
    rpToggle:SetFrameLevel(mainFrame:GetFrameLevel() + 50) -- Поверх окна
    rpToggle:EnableMouse(true) -- ВАЖНО: чтобы клик срабатывал
    rpToggle:SetScript("OnEnter", function(self) self:SetAlpha(1) end)
    rpToggle:SetScript("OnLeave", function(self) 
        if not NSQC4.Nowim.settingsOpen then self:SetAlpha(K.BTN_ALPHA or 0.01) end 
    end)

    local function UpdateRightTogglePosition()
        local KK = UI.Const or K
        local w = KK.RIGHT_WIDTH or 36
        rpToggle:ClearAllPoints()
        if RightPanel.IsOpen then
            rpToggle:SetPoint("BOTTOMRIGHT", mainFrame, "TOPRIGHT", -(w + 22), 0)
        else
            rpToggle:SetPoint("BOTTOMRIGHT", mainFrame, "TOPRIGHT", -28, 0)
        end
    end

    function RightPanel.Toggle()
        RightPanel.IsOpen = not RightPanel.IsOpen
        if RightPanel.IsOpen then rpFrame:Show() else rpFrame:Hide() end
        rpToggle:SetText(RightPanel.IsOpen and "<" or ">")
        UpdateRightTogglePosition()
        if UI.ReapplyLayout then UI.ReapplyLayout() end
    end
    rpToggle:SetScript("OnClick", RightPanel.Toggle)

    local function CreateToolButton(parent, iconText, tooltipText, onClick)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(28, 28)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        btn:SetBackdropColor(0.2, 0.2, 0.2, 1)
        btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        btn:SetFrameLevel(parent:GetFrameLevel() + 2)
        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        text:SetPoint("CENTER")
        text:SetText(iconText)
        text:SetTextColor(1, 0.82, 0)

        btn:SetScript("OnClick", onClick)
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            local tip = type(tooltipText) == "function" and tooltipText() or tooltipText
            GameTooltip:SetText(tip, 1, 1, 1)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        return btn
    end

    local btnSettings = CreateToolButton(rpFrame, "?", "Настройки констант", function()
        local CS = UI.ConstSettings
        if CS and CS.Show then CS.Show() end
    end)
    btnSettings:SetPoint("TOP", rpFrame, "TOP", 0, -4)

    local btnTwinks = CreateToolButton(rpFrame, "Т", "Управление твинками", function()
        if UI.AliasWindow then UI.AliasWindow.Show() else print("|cffff0000[Nowim]|r Окно твинков не готово.") end
    end)
    btnTwinks:SetPoint("TOP", btnSettings, "BOTTOM", 0, -4)

    local btnMerge = CreateToolButton(rpFrame, "О", "Объединять чаты персонажей", function(self)
        C.db.settings.mergeChats = not C.db.settings.mergeChats
        if C.db.settings.mergeChats then
            self:SetBackdropColor(0.1, 0.4, 0.1, 1)
        else
            self:SetBackdropColor(0.2, 0.2, 0.2, 1)
        end
        E.UpdateUI()
    end)
    btnMerge:SetPoint("TOP", btnTwinks, "BOTTOM", 0, -4)
    if C.db.settings.mergeChats then btnMerge:SetBackdropColor(0.1, 0.4, 0.1, 1) end

    local btnFont = CreateToolButton(rpFrame, "А", function()
        return "Размер шрифта: " .. (C.db.settings.fontSize or 12) .. "\nЛКМ — увеличить, ПКМ — уменьшить"
    end, function(self, button)
        local size = C.db.settings.fontSize or 12
        if button == "RightButton" then
            size = size - 1
            if size < 8 then size = 8 end
        else
            size = size + 1
            if size > 30 then size = 30 end
        end
        C.db.settings.fontSize = size
        E.UpdateUI()
        if GameTooltip:IsOwned(self) then
            GameTooltip:SetText("Размер шрифта: " .. size .. "\nЛКМ — увеличить, ПКМ — уменьшить", 1, 1, 1)
            GameTooltip:Show()
        end
    end)
    btnFont:SetPoint("TOP", btnMerge, "BOTTOM", 0, -4)

    local btnClear = CreateToolButton(rpFrame, "X", "Очистить историю", function()
        if C.db.activeTab then
            S.ClearHistory(C.db.activeTab)
            E.UpdateUI()
        end
    end)
    btnClear:SetPoint("TOP", btnFont, "BOTTOM", 0, -4)

    function UI.ReapplyLayout()
        local KK = UI.Const or K
        ApplyBorder()

        content:ClearAllPoints()
        content:SetPoint("TOPLEFT", KK.EDGE_PADDING or 4, -(KK.EDGE_PADDING or 4))
        content:SetPoint("BOTTOMRIGHT", -(KK.EDGE_PADDING or 4), KK.EDGE_PADDING or 4)

        lpFrame:ClearAllPoints()
        lpFrame:SetPoint("TOPLEFT", 0, -(KK.PANEL_HEIGHT or 20))
        lpFrame:SetPoint("BOTTOMLEFT", 0, 0)
        lpFrame:SetWidth(KK.LEFT_WIDTH or 140)

        rpFrame:ClearAllPoints()
        rpFrame:SetPoint("TOPRIGHT", 0, -(KK.PANEL_HEIGHT or 20))
        rpFrame:SetPoint("BOTTOMRIGHT", 0, 0)
        rpFrame:SetWidth(KK.RIGHT_WIDTH or 36)

        if UI.Tabs and UI.Tabs.Refresh then UI.Tabs.Refresh() end
        if LeftPanel.Refresh then LeftPanel.Refresh() end

        UpdateLeftTogglePosition()
        UpdateRightTogglePosition()

        if UI.ChatView and UI.ChatView.OnResize then UI.ChatView.OnResize() end
        if UI.Input and UI.Input.OnResize then UI.Input.OnResize() end
    end

    function mainFrame:ShowFrame()
        self:Show()
        self:Raise()
        ApplyBorder()
        if UI.ReapplyLayout then UI.ReapplyLayout() end
    end

    UpdateLeftTogglePosition()
    UpdateRightTogglePosition()
end)