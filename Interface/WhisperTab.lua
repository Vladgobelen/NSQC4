-- ============================================================================
-- NSQC4 / Interface / WhisperTab
-- Вкладка чата для шепота с историей.
-- Модуль: ui_whisper_tab.
-- ============================================================================

NSQC4.RegisterModule("ui_whisper_tab", function()

    nsDbc4.settings = nsDbc4.settings or {}
    nsDbc4.settings.whisper_history = nsDbc4.settings.whisper_history or {}
    local historyStore = nsDbc4.settings.whisper_history
    local MAX_HISTORY = 50

    -- Флаг для защиты от дублей
    local isProcessingWhisper = false
    local timeLeft = 0

    local function GetBaseName(name)
        if not name or name == "" then return "" end
        local base = name:match("^[^-]+") or name
        return strlower(base)
    end

    -- ========================================================================
    -- Ловим шёпоты
    -- ========================================================================
    local function CatchWhisper(self, event, msg, author, ...)
        if isProcessingWhisper then return false end
        isProcessingWhisper = true
        timeLeft = 0

        local key = GetBaseName(author)
        if not historyStore[key] then historyStore[key] = {} end

        table.insert(historyStore[key], {
            author = author,
            msg = msg,
            isIncoming = (event == "CHAT_MSG_WHISPER")
        })

        while #historyStore[key] > MAX_HISTORY do
            table.remove(historyStore[key], 1)
        end

        return false
    end

    -- Вешаем фильтр на все окна (флаг защитит от дублей)
    for i = 1, NUM_CHAT_WINDOWS do
        local f = _G["ChatFrame"..i]
        if f then
            ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", CatchWhisper)
            ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", CatchWhisper)
        end
    end

    -- Фрейм для сброса флага (без C_Timer)
    local resetFrame = CreateFrame("Frame")
    resetFrame:SetScript("OnUpdate", function(self, elapsed)
        if isProcessingWhisper then
            timeLeft = timeLeft + elapsed
            if timeLeft > 0.1 then
                isProcessingWhisper = false
                timeLeft = 0
            end
        end
    end)

    -- ========================================================================
    -- Отрисовка истории
    -- ========================================================================
    local function PlayHistory(chatFrame, playerName)
        local targetName = strlower(playerName)
        local history = nil

        for k, v in pairs(historyStore) do
            if strlower(k) == targetName then
                history = v
                break
            end
        end

        chatFrame:Clear()

        if not history or #history == 0 then
            chatFrame:AddMessage("--- История пуста ---", 0.5, 0.5, 0.5)
            return
        end

        chatFrame:AddMessage("--- История переписки ---", 0.5, 0.5, 0.5)
        for _, entry in ipairs(history) do
            if entry.isIncoming then
                local playerLink = "|Hplayer:" .. entry.author .. "|h[" .. entry.author .. "]|h"
                chatFrame:AddMessage(playerLink .. " шепчет: " .. entry.msg, 1.0, 0.5, 1.0)
            else
                local playerLink = "|Hplayer:" .. playerName .. "|h[" .. playerName .. "]|h"
                chatFrame:AddMessage("К " .. playerLink .. ": " .. entry.msg, 0.8, 0.5, 1.0)
            end
        end
        chatFrame:AddMessage("--- Конец истории ---", 0.5, 0.5, 0.5)
    end

    -- ========================================================================
    -- Создание вкладки
    -- ========================================================================
    local function FindTabByName(playerName)
        local tabName = "Шепот: " .. GetBaseName(playerName)
        for i = 1, NUM_CHAT_WINDOWS do
            local f = _G["ChatFrame"..i]
            if f and f.name and f.name:lower() == tabName then
                return f
            end
        end
        return nil
    end

    local function MoveToSeparateTab(playerName)
        if not playerName or playerName == "" then return end
        local baseName = GetBaseName(playerName)

        local existing = FindTabByName(baseName)
        if existing then
            FCF_DockFrame(existing)
            FCF_SelectDockFrame(existing)
            PlayHistory(existing, baseName)
            ChatFrame_OpenChat("/w " .. baseName .. " ", existing)
            return
        end

        local tabName = "Шепот: " .. baseName
        local chatFrame = FCF_OpenNewWindow(tabName)

        if chatFrame then
            FCF_DockFrame(chatFrame)
            FCF_SelectDockFrame(chatFrame)

            ChatFrame_RemoveAllMessageGroups(chatFrame)
            ChatFrame_AddMessageGroup(chatFrame, "WHISPER")
            ChatFrame_AddMessageGroup(chatFrame, "WHISPER_INFORM")

            -- Фильтры для отображения в этой вкладке
            ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", function(self, event, msg, author, ...)
                if self == chatFrame and GetBaseName(author) == baseName then return false end
                if self == chatFrame then return true end
                return false
            end)
            ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", function(self, event, msg, author, ...)
                if self == chatFrame and GetBaseName(author) == baseName then return false end
                if self == chatFrame then return true end
                return false
            end)

            PlayHistory(chatFrame, baseName)
            ChatFrame_OpenChat("/w " .. baseName .. " ", chatFrame)
        end
    end

    -- ========================================================================
    -- Хук на клик по вкладке
    -- ========================================================================
    hooksecurefunc("FCF_SelectDockFrame", function(frame)
        if frame and frame.name then
            local nameFromTab = frame.name:match("^Шепот: (.+)$")
            if nameFromTab then
                PlayHistory(frame, nameFromTab)
            end
        end
    end)

    -- ========================================================================
    -- Меню
    -- ========================================================================
    local function AddWhisperTabMenuEntry(name)
        if not name or name == UNKNOWNOBJECT then return end
        UIDropDownMenu_AddButton({
            text = "В отдельную вкладку",
            notCheckable = 1,
            func = function() MoveToSeparateTab(name) end,
        }, 1)
    end

    hooksecurefunc("UnitPopup_ShowMenu", function(dropdownMenu, which, unit, name)
        if which == "CHAT_ROSTER" or which == "FRIEND" then
            AddWhisperTabMenuEntry(name)
        end
    end)
    hooksecurefunc("FriendsFrame_ShowDropdown", function(name)
        AddWhisperTabMenuEntry(name)
    end)

    -- ========================================================================
    -- Метаданные
    -- ========================================================================
    NSQC4.SetModuleMeta("ui_whisper_tab", {
        label   = "Вкладка шепота",
        tooltip = "ПКМ по нику → вкладка с историей. ЛКМ по вкладке → обновить историю.",
        order   = 240,
    })

    -- ============================================================================
    -- ДОБАВЛЕНИЕ ПУНКТА В МЕНЮ CHATTER (DropDownList1)
    -- ============================================================================

    local NSQC4_CurrentTabToClose = nil

    -- ------------------------------------------------------------------------
    -- Окно подтверждения (Да / Нет)
    -- ------------------------------------------------------------------------
    local confirmFrame

    local function CreateConfirmDialog()
        if confirmFrame then return confirmFrame end

        local f = CreateFrame("Frame", "NSQC4TabCloseConfirm", UIParent)
        f:SetSize(320, 140)
        f:SetPoint("CENTER")
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetToplevel(true)
        f:EnableMouse(true)
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
        title:SetText("Подтверждение")

        local text = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        text:SetPoint("TOPLEFT", 12, -40)
        text:SetPoint("TOPRIGHT", -12, -40)
        text:SetJustifyH("LEFT")
        text:SetText("Закрыть вкладку?")
        f.text = text

        local yes = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        yes:SetSize(100, 24)
        yes:SetPoint("BOTTOMRIGHT", f, "BOTTOM", -55, 12)
        yes:SetText("Да")
        yes:SetScript("OnClick", function()
            f:Hide()
            if f.onYes then f.onYes() end
        end)

        local no = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        no:SetSize(100, 24)
        no:SetPoint("BOTTOMLEFT", f, "BOTTOM", 55, 12)
        no:SetText("Нет")
        no:SetScript("OnClick", function()
            f:Hide()
            if f.onNo then f.onNo() end
        end)

        f:SetScript("OnHide", function()
            f.onYes, f.onNo = nil, nil
        end)

        confirmFrame = f
        return f
    end

    local function ShowConfirm(message, onYes, onNo)
        local f = CreateConfirmDialog()
        f.text:SetText(message or "Закрыть вкладку?")
        f.onYes = onYes
        f.onNo  = onNo
        f:Show()
        f:Raise()
    end

    -- ------------------------------------------------------------------------
    -- Добавление пункта "Закрыть вкладку" в меню вкладки
    -- ------------------------------------------------------------------------
    local function AddButtonToDropDown()
        -- Если меню открыто и мы знаем, какую вкладку закрывать
        if DropDownList1 and DropDownList1:IsShown() and NSQC4_CurrentTabToClose then
            -- Проверяем, нет ли уже нашей кнопки (чтобы не дублировать)
            local found = false
            for i = 1, UIDROPDOWNMENU_MAXBUTTONS or 30 do
                local btn = _G["DropDownList1Button"..i]
                if btn and btn:IsShown() then
                    local text = _G["DropDownList1Button"..i.."Text"] or _G["DropDownList1Button"..i.."NormalText"]
                    if text and text:GetText() == "Закрыть вкладку" then
                        found = true
                        break
                    end
                end
            end

            if not found then
                -- Добавляем свой пункт с подтверждением
                local info = UIDropDownMenu_CreateInfo()
                info.text = "Закрыть вкладку"
                info.notCheckable = true
                info.func = function()
                    local tab = NSQC4_CurrentTabToClose
                    CloseDropDownMenus()
                    ShowConfirm("Закрыть вкладку «" .. (tab.name or "?") .. "»?",
                        function()
                            FCF_Close(tab)
                        end,
                        function()
                            -- Нет: ничего
                        end
                    )
                end
                UIDropDownMenu_AddButton(info, 1)

                -- Пересчитываем высоту меню, чтобы оно не обрезало текст
                UIDropDownMenu_Refresh(DropDownList1)
            end
        end
    end

    -- Перехватываем MouseUp на вкладках (как мы уже делали)
    local function HookTabsForClose()
        for i = 1, NUM_CHAT_WINDOWS do
            local chatFrame = _G["ChatFrame"..i]
            local tab = _G["ChatFrame"..i.."Tab"]

            if chatFrame and tab then
                tab:HookScript("OnMouseUp", function(self, button)
                    if button == "RightButton" then
                        NSQC4_CurrentTabToClose = chatFrame

                        -- Запускаем цикл, который ждет открытия меню и добавляет кнопку
                        local f = CreateFrame("Frame")
                        local ticks = 0
                        f:SetScript("OnUpdate", function(self, elapsed)
                            ticks = ticks + 1
                            AddButtonToDropDown()
                            if ticks > 10 then -- ждем ~0.5 сек
                                self:SetScript("OnUpdate", nil)
                            end
                        end)
                    end
                end)
            end
        end
    end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:SetScript("OnEvent", HookTabsForClose)

end)