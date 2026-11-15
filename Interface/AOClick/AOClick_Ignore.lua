-- ============================================================================
-- NSQC4 / Interface / AOClick / Ignore
-- ОТДЕЛЬНЫЙ модуль ui_ao_ignore: игнор-лист.
--   * Скрытие строк чата, где встречается ник из ignoreList.
--   * Окно списка игнорируемых с кнопкой удаления справа от ника.
--   * Кнопка на SlashPanel.
-- ============================================================================

-- Метаданные — сразу при загрузке, чтобы order=195 попал в сортировку.
NSQC4.SetModuleMeta("ui_ao_ignore", {
    label   = "Игнор чата",
    tooltip = "Скрытие строк чата с выбранными никами. Окно: /ns_ignore или кнопка «I» на панели.",
    order   = 195,
})

NSQC4.RegisterModule("ui_ao_ignore", function()

    local A = NSQC4.AOClick
    if not A then return end

    local ignoreList = nsDbc4.settings.ignoreList

    -- ========================================================================
    -- API
    -- ========================================================================
    local function IsIgnored(name)
        local clean = A.CleanName(name)
        return clean and ignoreList[clean] and true or false
    end

    local function AddIgnore(name)
        local clean = A.CleanName(name)
        if not clean then return end
        ignoreList[clean] = true
        if NSQC4.AOClick_Ignore_RefreshWindow then
            NSQC4.AOClick_Ignore_RefreshWindow()
        end
    end

    local function RemoveIgnore(name)
        local clean = A.CleanName(name)
        if not clean then return end
        ignoreList[clean] = nil
        if NSQC4.AOClick_Ignore_RefreshWindow then
            NSQC4.AOClick_Ignore_RefreshWindow()
        end
    end

    local function ToggleIgnore(name)
        local clean = A.CleanName(name)
        if not clean then return end
        if ignoreList[clean] then
            RemoveIgnore(clean)
        else
            AddIgnore(clean)
        end
    end

    NSQC4.AOClick_Ignore_IsIgnored = IsIgnored
    NSQC4.AOClick_Ignore_Add       = AddIgnore
    NSQC4.AOClick_Ignore_Remove    = RemoveIgnore
    NSQC4.AOClick_Ignore_Toggle    = ToggleIgnore

    -- ========================================================================
    -- Скрытие строк чата с игнорируемым ником
    -- ========================================================================
    local function MessageHasIgnoredName(msg)
        if not msg or msg == "" then return false end
        for nick in msg:gmatch("|Hplayer:([^|:]+)") do
            local clean = A.CleanName(nick)
            if clean and ignoreList[clean] then
                return true
            end
        end
        return false
    end

    local InitFrame = CreateFrame("Frame")
    InitFrame:RegisterEvent("PLAYER_LOGIN")
    local hooked = false

    InitFrame:SetScript("OnEvent", function(self)
        if hooked then return end
        hooked = true
        self:UnregisterAllEvents()

        local function InstallHook(chatFrame)
            if not chatFrame then return end
            local oldAddMessage = chatFrame.AddMessage
            chatFrame.AddMessage = function(self2, msg, ...)
                if msg and type(msg) == "string" and MessageHasIgnoredName(msg) then
                    return
                end
                return oldAddMessage(self2, msg, ...)
            end
        end

        for i = 1, NUM_CHAT_WINDOWS do
            InstallHook(_G["ChatFrame"..i])
        end
        if DEFAULT_CHAT_FRAME then
            InstallHook(DEFAULT_CHAT_FRAME)
        end
    end)

    -- ========================================================================
    -- Окно списка игнорируемых
    -- ========================================================================
    local ignoreFrame

    local function RefreshIgnoreWindow()
        if not ignoreFrame then return end
        local scroll = ignoreFrame.scroll
        local content = scroll.content

        -- Очистка
        for _, child in ipairs({content:GetChildren()}) do
            child:Hide()
            child:SetParent(nil)
        end
        content.rows = {}

        -- Сбор имён
        local names = {}
        for name in pairs(ignoreList) do
            table.insert(names, name)
        end
        table.sort(names)

        local ROW_H = 24
        local y = 0
        for i, name in ipairs(names) do
            local row = CreateFrame("Frame", nil, content)
            row:SetSize(340, ROW_H)
            row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
            content.rows[#content.rows + 1] = row

            local fs = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            fs:SetPoint("LEFT", row, "LEFT", 6, 0)
            fs:SetText(name)

            local del = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            del:SetSize(60, 20)
            del:SetPoint("RIGHT", row, "RIGHT", -4, 0)
            del:SetText("Удалить")
            del:SetScript("OnClick", function()
                RemoveIgnore(name)
            end)

            y = y + ROW_H + 2
        end

        content:SetHeight(math.max(y, 1))
        scroll:UpdateScrollChildRect()
    end
    NSQC4.AOClick_Ignore_RefreshWindow = RefreshIgnoreWindow

    local function CreateIgnoreWindow()
        if ignoreFrame then return ignoreFrame end

        local f = CreateFrame("Frame", "NSQC4AOClickIgnoreWindow", UIParent)
        f:SetSize(380, 400)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:SetToplevel(true)
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop",  f.StopMovingOrSizing)
        f:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        f:SetBackdropColor(0, 0, 0, 1)
        f:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

        local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 12, -10)
        title:SetText("Игнор-лист")

        local scroll = CreateFrame("ScrollFrame", "NSQC4AOClickIgnoreScroll", f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 10, -36)
        scroll:SetPoint("BOTTOMRIGHT", -30, 40)

        local content = CreateFrame("Frame", nil, scroll)
        content:SetSize(340, 1)
        scroll:SetScrollChild(content)
        scroll.content = content

        f.scroll = scroll

        local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        close:SetSize(100, 24)
        close:SetPoint("BOTTOMRIGHT", -10, 10)
        close:SetText("Закрыть")
        close:SetScript("OnClick", function() f:Hide() end)

        ignoreFrame = f
        return f
    end

    local function OpenIgnoreWindow()
        CreateIgnoreWindow()
        RefreshIgnoreWindow()
        ignoreFrame:Show()
        ignoreFrame:Raise()
    end
    NSQC4.AOClick_Ignore_Open = OpenIgnoreWindow

    -- ========================================================================
    -- Кнопка на SlashPanel
    -- ========================================================================
    if NSQC4.SlashPanel_RegisterButton then
        NSQC4.SlashPanel_RegisterButton(
            "I",                     -- label
            "/ns_ignore",            -- cmd
            "Игнор-лист: скрыть строки чата с выбранными никами",  -- desc
            function() OpenIgnoreWindow() end
        )
    end

    -- ========================================================================
    -- Слэш-команда
    -- ========================================================================
    SLASH_NS_IGNORE1 = "/ns_ignore"
    SlashCmdList["NS_IGNORE"] = function()
        OpenIgnoreWindow()
    end

end)