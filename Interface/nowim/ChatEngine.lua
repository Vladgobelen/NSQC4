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

    function E.OpenDialog(key)
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

        C.db.activeTab = key
        C.db.unread[key] = 0

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
        if not text or text == "" then return end
        
        -- Если введена команда (начинается со слэша)
        if text:sub(1, 1) == "/" then
            local cmd, rest = text:match("^/(%S+)%s*(.*)$")
            
            if cmd == "run" or cmd == "script" then
                -- Выполняем Lua-код напрямую
                local ok, err = pcall(RunScript, rest)
                if not ok then
                    print("|cffff0000[Nowim]|r Ошибка: " .. tostring(err))
                end
            elseif cmd == "reload" then
                -- Перезагрузка интерфейса
                ReloadUI()
            elseif cmd == "console" then
                -- Установка CVar (например /console reloadui)
                local cvar, val = rest:match("^(%S+)%s*(.*)$")
                if cvar and val then
                    SetCVar(cvar, val)
                end
            else
                -- Для остальных команд (например /say) используем стандартный чат,
                -- но с принудительным выполнением через RunScript (если это Lua-код).
                -- Если это не Lua, RunScript просто проигнорирует или выдаст ошибку.
                local ok = pcall(RunScript, text:sub(2))
                if not ok then
                    -- Если не сработало как код, пробуем выполнить как слэш-команду
                    -- (это может не сработать без таймера, поэтому просто выводим ошибку)
                    print("|cffff0000[Nowim]|r Неизвестная команда: " .. tostring(cmd))
                end
            end
            return
        end

        -- Обычное сообщение в чат аддона
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

end)