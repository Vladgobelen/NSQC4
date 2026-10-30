-- ============================================================================
-- NSQC4 / nowim / ChatEngine
-- ============================================================================

NSQC4.RegisterModule("nowim", function()

    local C = NSQC4.Nowim.Config
    local S = NSQC4.Nowim.Storage
    local N = NSQC4.Nowim.Network
    local A = NSQC4.Nowim.Aliases

    local E = {}
    NSQC4.Nowim.ChatEngine = E

    C.db.unread = C.db.unread or {}
    C.db.openTabs = C.db.openTabs or {}
    C.db.savedScroll = C.db.savedScroll or {}

    function E.OpenDialog(key, silent)
        if not key or key == "" then return end
        if type(key) ~= "string" then return end

        C.db.dialogs[key] = C.db.dialogs[key] or { messages = {} }

        local isOpen = false
        for _, tabKey in ipairs(C.db.openTabs) do
            if tabKey == key then isOpen = true; break end
        end

        if not isOpen then
            table.insert(C.db.openTabs, key)
            if C.db.settings.autoScroll then
                C.db.savedScroll[key] = 999999
            else
                C.db.savedScroll[key] = 0
            end
        end

        if not silent then
            C.db.activeTab = key
            C.db.unread[key] = 0
        end

        E.UpdateUI()
    end

    function E.CloseTab(key)
        for i, tabKey in ipairs(C.db.openTabs) do
            if tabKey == key then
                table.remove(C.db.openTabs, i)
                break
            end
        end

        if C.db.activeTab == key then
            C.db.activeTab = C.db.openTabs[#C.db.openTabs]
        end

        E.UpdateUI()
    end

    function E.SendMessage(text)
        local target = C.db.activeTab
        if not target then return end
        N.QueueMessage(target, text)
    end

    function E.OnIncomingMessage(sender, targetKey, text)
        if C.db.activeTab ~= targetKey then
            C.db.unread[targetKey] = (C.db.unread[targetKey] or 0) + 1
        end
        E.UpdateUI()
    end

    function E.UpdateUI()
        local UI = NSQC4.Nowim.UI
        if not UI then return end

        if UI.Tabs and UI.Tabs.Refresh then
            UI.Tabs.Refresh()
        end
        if UI.Chat and UI.Chat.Refresh then
            UI.Chat.Refresh()
        end
        if UI.LeftPanel and UI.LeftPanel.Refresh then
            UI.LeftPanel.Refresh()
        end
    end

    -- ========================================================================
    -- КОМАНДЫ
    -- ========================================================================
    SLASH_NOWIM_CHAT1 = "/nowim"
    SlashCmdList["NOWIM_CHAT"] = function(msg)
        msg = (msg or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if msg ~= "" then
            E.OpenDialog(msg)
        end
        if NSQC4.Nowim.UI and NSQC4.Nowim.UI.MainFrame then
            NSQC4.Nowim.UI.MainFrame:ShowFrame()
        end
    end

    SLASH_NOWIM_ARCHIVE1 = "/nowim_archive"
    SlashCmdList["NOWIM_ARCHIVE"] = function(msg)
        msg = (msg or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if msg == "" then
            print("|cffff0000[Nowim]|r Укажите ключ чата: /nowim_archive GUILD, GENERAL или ник")
            return
        end

        local key = msg:upper()
        -- Поиск по нику (если это не канал)
        if not C.db.channels[key] then key = A.GetMainName(msg) end

        local archive = C.db.archives[key]
        
        if not archive or not archive.messages or #archive.messages == 0 then
            print("|cff00ff00[Nowim]|r Архив для " .. key .. " пуст.")
            return
        end

        print("|cff00ff00[Nowim]|r Архив " .. key .. " (" .. #archive.messages .. " сообщений):")
        
        -- Выводим последние 15 сообщений в чат
        local startIdx = math.max(1, #archive.messages - 15)
        for i = startIdx, #archive.messages do
            local m = archive.messages[i]
            print(string.format("[%s] %s: %s", m.time or "??:??", m.char or "???", m.text or ""))
        end
    end

end)