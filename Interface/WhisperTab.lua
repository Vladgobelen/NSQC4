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

end)