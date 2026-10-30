-- ============================================================================
-- NSQC4 / nowim / UI / ConstSettings
-- ============================================================================

NSQC4.RegisterModule("nowim", function()
    local C = NSQC4.Nowim.Config
    local UI = NSQC4.Nowim.UI

    local FIELDS = {
        { key = "EDGE_PADDING",   label = "Отступ от края окна" },
        { key = "PANEL_HEIGHT",   label = "Отступ сверху панелей" },
        { key = "LEFT_WIDTH",     label = "Ширина левой панели" },
        { key = "RIGHT_WIDTH",    label = "Ширина правой панели" },
        { key = "TAB_WIDTH",      label = "Ширина вкладки" },
        { key = "TAB_HEIGHT",     label = "Высота вкладки" },
        { key = "BUBBLE_PADDING", label = "Отступ текста в облаке" },
        { key = "GAP",            label = "Зазор между облаками" },
        { key = "CHAT_PADDING_L", label = "Сдвиг чужих сообщений" },
        { key = "CHAT_PADDING_R", label = "Сдвиг своих сообщений" },
        { key = "CHAT_RIGHT_PAD", label = "Зазор справа (скроллбар)" },
        { key = "CHAT_PAD_TOP",    label = "Отступ чата сверху" },
        { key = "CHAT_PAD_BOTTOM", label = "Отступ чата снизу (над вводом)" },
        { key = "CHAT_PAD_PANEL",  label = "Зазор чата до панелей" },
        { key = "INPUT_HEIGHT",   label = "Высота поля ввода" },
    }

    C.db.settings.offsets = C.db.settings.offsets or {}
    local offsets = C.db.settings.offsets
    local base = {}
    local MIN = {
        INPUT_HEIGHT = 5, TAB_WIDTH = 5, TAB_HEIGHT = 5,
        LEFT_WIDTH = 5, RIGHT_WIDTH = 5, GAP = 0, BUBBLE_PADDING = 0,
        CHAT_RIGHT_PAD = 0, CHAT_PAD_TOP = -10, CHAT_PAD_BOTTOM = -10, CHAT_PAD_PANEL = -10,
    }

    local function RefreshBase()
        local K = UI.Const
        if not K then return end
        for _, f in ipairs(FIELDS) do
            base[f.key] = (K[f.key] or 0) - (offsets[f.key] or 0)
        end
    end

    local function ApplyOffset(key)
        local K = UI.Const
        if not K then return end
        local b = base[key] or 0
        local o = offsets[key] or 0
        local v = b + o
        local m = MIN[key]
        if m and v < m then v = m end
        K[key] = v
    end

    local function ApplyAll()
        for _, f in ipairs(FIELDS) do ApplyOffset(f.key) end
    end

    local function Rebuild()
        if UI.ReapplyLayout then UI.ReapplyLayout()
        else
            if UI.Tabs and UI.Tabs.Refresh then UI.Tabs.Refresh() end
            if UI.Chat and UI.Chat.OnResize then UI.Chat.OnResize() end
            if UI.Input and UI.Input.OnResize then UI.Input.OnResize() end
        end
    end

    local win = CreateFrame("Frame", "NSQC4_NowimConstSettings", UIParent)
    win:SetSize(380, 600)
    win:SetPoint("CENTER")
    win:SetFrameStrata("DIALOG")
    win:SetMovable(true)
    win:EnableMouse(true)
    win:SetClampedToScreen(true)
    win:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1, insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    win:SetBackdropColor(0, 0, 0, 0.95)
    win:SetBackdropBorderColor(1, 1, 1, 1)
    win:Hide()

    local title = win:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -8)
    title:SetText("Настройки констант")

    local close = CreateFrame("Button", nil, win, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function() win:Hide() end)

    local header = CreateFrame("Frame", nil, win)
    header:SetPoint("TOPLEFT", 30, 0)
    header:SetPoint("TOPRIGHT", -30, 0)
    header:SetHeight(28)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() win:StartMoving() end)
    header:SetScript("OnDragStop", function() win:StopMovingOrSizing() end)

    local scroll = CreateFrame("ScrollFrame", "NSQC4_NowimConstSettingsScroll", win, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -34)
    scroll:SetPoint("BOTTOMRIGHT", -28, 40)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(330)
    content:SetHeight(1)
    scroll:SetScrollChild(content)

    local ROW_H = 34
    local sliders = {}

    local function MakeSlider(parent, y, field)
        local row = CreateFrame("Frame", nil, parent)
        row:SetPoint("TOPLEFT", 0, -y)
        row:SetPoint("TOPRIGHT", 0, -y)
        row:SetHeight(ROW_H)

        local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", 2, 0)
        label:SetText(field.label)

        local valText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        valText:SetPoint("TOPRIGHT", -2, 0)

        local function UpdateValText()
            local b = base[field.key] or 0
            local o = offsets[field.key] or 0
            valText:SetText(string.format("base=%d  offset=%+d  = %d", b, o, b + o))
        end
        UpdateValText()

        local sliderName = "NSQC4_NowimConstSlider_" .. field.key
        local slider = CreateFrame("Slider", sliderName, row, "OptionsSliderTemplate")
        slider:SetPoint("BOTTOMLEFT", 2, 0)
        slider:SetPoint("BOTTOMRIGHT", -2, 0)
        slider:SetHeight(16)
        slider:SetMinMaxValues(-50, 50)
        slider:SetValueStep(1)
        if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
        slider:SetValue(offsets[field.key] or 0)

        local low  = _G[sliderName .. "Low"]
        local high = _G[sliderName .. "High"]
        local text = _G[sliderName .. "Text"]
        if low  then low:Hide()  end
        if high then high:Hide() end
        if text then text:Hide() end

        slider:SetScript("OnValueChanged", function(self, value)
            value = math.floor(value + 0.5)
            offsets[field.key] = value
            ApplyOffset(field.key)
            UpdateValText()
            Rebuild()
        end)

        sliders[field.key] = { slider = slider, update = UpdateValText }
        return row
    end

    local y = 0
    for _, f in ipairs(FIELDS) do
        MakeSlider(content, y, f)
        y = y + ROW_H
    end

    local function MakeCheckbox(parent, y, labelText, getValue, setValue)
        local row = CreateFrame("Frame", nil, parent)
        row:SetPoint("TOPLEFT", 0, -y)
        row:SetPoint("TOPRIGHT", 0, -y)
        row:SetHeight(24)

        local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        cb:SetSize(24, 24)
        cb:SetPoint("LEFT", 2, 0)

        local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", cb, "RIGHT", 6, 0)
        label:SetText(labelText)

        local function Update() cb:SetChecked(getValue() and true or false) end
        Update()

        cb:SetScript("OnClick", function(self)
            setValue(self:GetChecked() and true or false)
            Update()
            Rebuild()
        end)
        return row
    end

    y = y + 8
    MakeCheckbox(content, y, "Отображать рамку окна",
        function() return C.db.settings.showBorder end,
        function(v) C.db.settings.showBorder = v end)
    y = y + 28

    MakeCheckbox(content, y, "Отображать строку ввода в покое",
        function() return C.db.settings.showInputIdle end,
        function(v) C.db.settings.showInputIdle = v end)
    y = y + 28

    content:SetHeight(math.max(1, y))

    local reset = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
    reset:SetSize(90, 22)
    reset:SetPoint("BOTTOMLEFT", 8, 8)
    reset:SetText("Сброс")
    reset:SetScript("OnClick", function()
        for _, f in ipairs(FIELDS) do offsets[f.key] = 0 end
        ApplyAll()
        for _, s in pairs(sliders) do
            s.slider:SetValue(0)
            s.update()
        end
        Rebuild()
    end)

    local btnClose = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
    btnClose:SetSize(90, 22)
    btnClose:SetPoint("BOTTOMRIGHT", -8, 8)
    btnClose:SetText("Закрыть")
    btnClose:SetScript("OnClick", function() win:Hide() end)

    local function InitWhenReady()
        if not UI.Const then return false end
        RefreshBase()
        ApplyAll()
        for _, s in pairs(sliders) do s.update() end
        return true
    end

    if not InitWhenReady() then
        local f = CreateFrame("Frame")
        f:RegisterEvent("PLAYER_LOGIN")
        f:SetScript("OnEvent", function(self)
            self:UnregisterAllEvents()
            if not InitWhenReady() then
                print("|cffff0000[Nowim]|r ConstSettings: UI.Const так и не появился.")
            end
        end)
    end

    -- ========================================================================
    -- ОТЛАДКА И УПРАВЛЕНИЕ КНОПКАМИ
    -- ========================================================================
    local CS = {}
    UI.ConstSettings = CS

    local buttonsToShow = { 
        "NSQC4_NowimLeftToggle", 
        "NSQC4_NowimRightToggle" 
    }

    local function SetButtonsAlpha(alpha)
        for _, name in ipairs(buttonsToShow) do
            local btn = _G[name]
            if btn then 
                btn:SetAlpha(alpha) 
            end
        end
    end

    -- Функция отладки: показывает в чат, где кнопки и какая у них альфа
    local function DebugButtons()
        print("|cff00ff00[Nowim Debug]|r --- Проверка кнопок ---")
        
        -- Левая кнопка
        local leftBtn = _G["NSQC4_NowimLeftToggle"]
        if leftBtn then
            print("LeftToggle существует. Alpha:", leftBtn:GetAlpha(), "Shown:", tostring(leftBtn:IsShown()))
            print("LeftToggle родитель:", leftBtn:GetParent():GetName() or "Без имени")
        else
            print("|cffff0000LeftToggle НЕ НАЙДЕН!|r")
        end

        -- Правая кнопка
        local rightBtn = _G["NSQC4_NowimRightToggle"]
        if rightBtn then
            print("RightToggle существует. Alpha:", rightBtn:GetAlpha(), "Shown:", tostring(rightBtn:IsShown()))
            print("RightToggle родитель:", rightBtn:GetParent():GetName() or "Без имени")
        else
            print("|cffff0000RightToggle НЕ НАЙДЕН!|r")
        end

        -- Кнопка закрытия окна (крестик)
        local closeBtn = _G["NSQC4_NowimMainFrameCloseButton"]
        if closeBtn then
            print("CloseBtn существует. Alpha:", closeBtn:GetAlpha())
        else
            print("|cffff0000CloseBtn не имеет имени (это нормально, если создан через CreateFrame без имени)|r")
        end
        
        -- Контейнер вкладок
        local tabs = UI.Tabs
        if tabs and tabs.Buttons then
            print("Вкладок создано:", #tabs.Buttons)
        end
        
        print("|cff00ff00[Nowim Debug]|r --- Конец проверки ---")
    end

    function CS.Show()
        win:Show()
        win:Raise()
        NSQC4.Nowim.settingsOpen = true
        SetButtonsAlpha(1)
        DebugButtons() -- ВЫЗЫВАЕМ ОТЛАДКУ ПРИ ОТКРЫТИИ
    end

    function CS.Hide()
        win:Hide()
        NSQC4.Nowim.settingsOpen = false
        SetButtonsAlpha(0.01)
    end

    function CS.Toggle()
        if win:IsShown() then CS.Hide() else CS.Show() end
    end
end)