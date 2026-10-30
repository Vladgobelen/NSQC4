-- ============================================================================
-- NSQC4 / nowim / UI / Tabs
-- ============================================================================

NSQC4.RegisterModule("nowim", function()
    local C = NSQC4.Nowim.Config
    local E = NSQC4.Nowim.ChatEngine
    local UI = NSQC4.Nowim.UI

    local T = {}
    UI.Tabs = T
    local mainFrame = UI.MainFrame

    C.db.settings.filters = C.db.settings.filters or {
        GUILD = true, RAID = true, PARTY = true, WHISPER = true, SYSTEM = true, SAY = true, YELL = true
    }
    local filters = C.db.settings.filters

    local tabContainer = CreateFrame("Frame", nil, mainFrame)
    tabContainer:SetPoint("BOTTOMLEFT", mainFrame, "TOPLEFT", 30, 0) 
    tabContainer:SetPoint("BOTTOMRIGHT", mainFrame, "TOPRIGHT", -30, 0)
    tabContainer:SetHeight(24)
    tabContainer:SetFrameLevel(mainFrame:GetFrameLevel() + 10)
    
    tabContainer:SetAlpha(0.01)
    tabContainer:EnableMouse(true)

    -- Логика прозрачности (проявляется при наведении или непрочитанных)
    tabContainer:SetScript("OnUpdate", function(self)
        local hasUnread = false
        for _, key in ipairs(C.db.openTabs or {}) do
            if (C.db.unread[key] or 0) > 0 then hasUnread = true break end
        end
        if hasUnread then self:SetAlpha(1) return end

        local isOver = self:IsMouseOver()
        if not isOver then
            for _, btn in pairs(T.Buttons) do
                if btn:IsMouseOver() then isOver = true break end
            end
        end
        self:SetAlpha(isOver and 1 or 0.01)
    end)

    mainFrame.Tabs = tabContainer
    T.Buttons = {}
    local tabButtons = T.Buttons
    local TAB_WIDTH = 30
    local TAB_HEIGHT = 24

    local function GetTabLetter(key)
        if key == "GENERAL" then return "О" end
        if key == "GUILD" then return "Г" end
        if key == "OFFICER" then return "О" end
        if key == "RAID" then return "Р" end
        if type(key) ~= "string" then return "?" end
        return (key:match("^([%z\1-\127\194-\244][\128-\191]*)") or "?"):upper()
    end

    -- ========================================================================
    -- Меню настроек (ПКМ по вкладке)
    -- ========================================================================
    local menuFrame
    local function ShowTabMenu(btn)
        if not menuFrame then
            menuFrame = CreateFrame("Frame", "NSQC4NowimTabMenu", UIParent, "UIDropDownMenuTemplate")
        end
        
        UIDropDownMenu_Initialize(menuFrame, function(self, level)
            local info = UIDropDownMenu_CreateInfo()
            
            info.text = "|cffffd100Фильтры общего чата:|r"
            info.isTitle = true
            info.notCheckable = true
            UIDropDownMenu_AddButton(info, level)

            local filterList = {
                { key = "GUILD",   text = "Гильдия" },
                { key = "RAID",    text = "Рейд" },
                { key = "PARTY",   text = "Группа" },
                { key = "WHISPER", text = "Шепот" },
                { key = "SYSTEM",  text = "Системные (Лут/Ачивки)" },
                { key = "SAY",     text = "Сказать (/say)" },
                { key = "YELL",    text = "Крик (/yell)" },
            }

            for _, f in ipairs(filterList) do
                info = UIDropDownMenu_CreateInfo()
                info.text = f.text
                info.checked = filters[f.key]
                info.keepShownOnClick = true
                info.func = function() filters[f.key] = not filters[f.key] end
                UIDropDownMenu_AddButton(info, level)
            end

            info = UIDropDownMenu_CreateInfo()
            info.text = "|cffffd100Каналы:|r"
            info.isTitle = true
            info.notCheckable = true
            UIDropDownMenu_AddButton(info, level)

            for id, data in pairs(C.db.channels) do
                if data.type == "CHANNEL" then
                    info = UIDropDownMenu_CreateInfo()
                    info.text = data.name
                    info.checked = filters[data.name] ~= false
                    info.keepShownOnClick = true
                    info.func = function() 
                        filters[data.name] = not info.checked
                    end
                    UIDropDownMenu_AddButton(info, level)
                end
            end

            info = UIDropDownMenu_CreateInfo()
            info.text = ""
            info.notCheckable = true
            info.disabled = true
            UIDropDownMenu_AddButton(info, level)

            info = UIDropDownMenu_CreateInfo()
            info.text = "Автопрокрутка"
            info.checked = C.db.settings.autoScroll
            info.func = function() C.db.settings.autoScroll = not C.db.settings.autoScroll end
            UIDropDownMenu_AddButton(info, level)

            info = UIDropDownMenu_CreateInfo()
            info.text = "Перехватывать Enter"
            info.checked = C.db.settings.interceptEnter
            info.func = function() 
                C.db.settings.interceptEnter = not C.db.settings.interceptEnter 
                if NSQC4.Nowim.ApplyEnterBinding then NSQC4.Nowim.ApplyEnterBinding() end
                if NSQC4.Nowim.UpdateSystemChatVisibility then NSQC4.Nowim.UpdateSystemChatVisibility() end
            end
            UIDropDownMenu_AddButton(info, level)
        end)
        ToggleDropDownMenu(1, nil, menuFrame, btn, 0, 0)
    end

    -- ========================================================================
    -- Создание вкладки
    -- ========================================================================
    local function CreateTabButton(key)
        -- Сама вкладка
        local btn = CreateFrame("Button", nil, tabContainer)
        btn:SetSize(TAB_WIDTH, TAB_HEIGHT)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 0 }
        })
        btn:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
        btn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        text:SetPoint("CENTER", 0, 2)
        text:SetText(GetTabLetter(key))
        text:SetTextColor(1, 1, 1)

        -- Кнопка закрытия (крестик) - создаем НАПРЯМУЮ В tabContainer
        local close = CreateFrame("Button", nil, tabContainer)
        close:SetSize(14, 14)
        close:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
        close:SetFrameLevel(tabContainer:GetFrameLevel() + 20) -- Самый верхний слой
        close:EnableMouse(true)
        close:Hide()
        
        -- Привязываем крестик к правому верхнему углу вкладки
        -- (позиция будет обновляться в T.Refresh)
        
        close:SetScript("OnClick", function(self, button)
            if button == "LeftButton" then 
                E.CloseTab(key) 
            end
        end)

        -- Клик по самой вкладке
        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        btn:SetScript("OnClick", function(self, button)
            if button == "RightButton" then 
                ShowTabMenu(self) 
            else 
                E.OpenDialog(key) 
            end
        end)
        
        -- Показ крестика при наведении на вкладку
        btn:SetScript("OnEnter", function(self)
            close:Show()
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:SetText(key, 1, 1, 1)
            GameTooltip:AddLine("ЛКМ — открыть, ПКМ — настройки", 0.6, 0.6, 0.6)
            GameTooltip:Show()
        end)
        
        btn:SetScript("OnLeave", function()
            -- Скрываем крестик, если мышь не на нем
            if not close:IsMouseOver() then
                close:Hide()
            end
            GameTooltip:Hide()
        end)
        
        -- Если ушли с крестика, скрываем его (если мышь не на вкладке)
        close:SetScript("OnLeave", function(self)
            if not btn:IsMouseOver() then
                self:Hide()
            end
        end)

        btn.close = close -- Сохраняем ссылку
        tabButtons[key] = btn
        return btn
    end

    -- ========================================================================
    -- Обновление вкладок
    -- ========================================================================
    function T.Refresh()
        local openTabs = C.db.openTabs
        local active = C.db.activeTab

        for _, btn in pairs(tabButtons) do 
            btn:Hide() 
            if btn.close then btn.close:Hide() end
        end
        if not openTabs then return end

        local xPos = 0
        for _, key in ipairs(openTabs) do
            local btn = tabButtons[key] or CreateTabButton(key)
            btn:ClearAllPoints()
            btn:SetPoint("BOTTOMLEFT", tabContainer, "BOTTOMLEFT", xPos, 0) 
            btn:Show()

            -- Позиционируем крестик относительно вкладки
            if btn.close then
                btn.close:ClearAllPoints()
                btn.close:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 2, 2)
            end

            local unread = C.db.unread[key] or 0

            if key == active then
                btn:SetBackdropColor(0.1, 0.1, 0.1, 1)
                btn:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
                btn:SetHeight(TAB_HEIGHT + 2)
            else
                btn:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
                btn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
                btn:SetHeight(TAB_HEIGHT)
            end
            
            -- Красная точка (слева, непрочитанные)
            if unread > 0 then
                if not btn.RedDot then
                    btn.RedDot = btn:CreateTexture(nil, "OVERLAY")
                    btn.RedDot:SetSize(6, 6)
                    btn.RedDot:SetPoint("TOPLEFT", 2, -2)
                    btn.RedDot:SetTexture("Interface\\Buttons\\WHITE8x8")
                    btn.RedDot:SetVertexColor(1, 0, 0, 1)
                end
                btn.RedDot:Show()
            elseif btn.RedDot then
                btn.RedDot:Hide()
            end

            xPos = xPos + TAB_WIDTH + 2
        end
    end
end)