-- ============================================================================
-- NSQC4 / Interface / WhisperTab
-- ПКМ по нику в чате → «В отдельную вкладку».
-- Создаёт вкладку чата «Шепот: <ник>» с фильтром только этого игрока.
-- Модуль: ui_whisper_tab.
-- ============================================================================

NSQC4.RegisterModule("ui_whisper_tab", function()

    -- Хранилище созданных вкладок: [playerName] = chatFrame
    local whisperTabs = {}

    -- ========================================================================
    -- Закрытие вкладки
    -- ========================================================================
    local function CloseWhisperTab(playerName)
        local f = whisperTabs[playerName]
        if f then
            FCF_Close(f)
            whisperTabs[playerName] = nil
            print("|cff00ff00[NSQC4]|r Вкладка для " .. playerName .. " закрыта.")
        end
    end

    -- ========================================================================
    -- Создание / активация отдельной вкладки
    -- ========================================================================
    local function MoveToSeparateTab(playerName)
        if not playerName or playerName == "" then return end

        -- Если уже создана — просто активируем
        local existing = whisperTabs[playerName]
        if existing then
            FCF_DockFrame(existing)
            FCF_SelectDockFrame(existing)
            ChatFrame_OpenChat("/w " .. playerName .. " ", existing)
            return
        end

        local tabName = "Шепот: " .. playerName
        local chatFrame = FCF_OpenNewWindow(tabName)

        if chatFrame then
            FCF_DockFrame(chatFrame)
            FCF_SelectDockFrame(chatFrame)

            ChatFrame_RemoveAllMessageGroups(chatFrame)
            ChatFrame_AddMessageGroup(chatFrame, "WHISPER")
            ChatFrame_AddMessageGroup(chatFrame, "WHISPER_INFORM")

            ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", function(self, event, msg, author, ...)
                if self == chatFrame and author == playerName then
                    return false
                elseif self == chatFrame then
                    return true
                end
                return false
            end)

            ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", function(self, event, msg, author, ...)
                if self == chatFrame and author == playerName then
                    return false
                elseif self == chatFrame then
                    return true
                end
                return false
            end)

            whisperTabs[playerName] = chatFrame

            -- 关键：在标签页上挂右键，直接关闭
            local tab = _G[chatFrame:GetName() .. "Tab"]
            if tab then
                tab:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                tab:HookScript("OnClick", function(self, button)
                    if button == "RightButton" then
                        CloseWhisperTab(playerName)
                    end
                end)
            end

            ChatFrame_OpenChat("/w " .. playerName .. " ", chatFrame)
            print("|cff00ff00[NSQC4]|r Создана вкладка " .. tabName .. " (ПКМ по вкладке — закрыть)")
        end
    end

    -- ========================================================================
    -- Меню по нику: «В отдельную вкладку» + «Закрыть вкладку» (если есть)
    -- ========================================================================
    local function AddWhisperTabMenuEntry(name)
        if not name or name == UNKNOWNOBJECT then return end

        UIDropDownMenu_AddButton({
            text = "В отдельную вкладку",
            notCheckable = 1,
            func = function()
                MoveToSeparateTab(name)
            end,
        }, 1)

        -- 如果这个玩家已经有独立标签页，显示关闭选项
        if whisperTabs[name] then
            UIDropDownMenu_AddButton({
                text = "Закрыть вкладку шепота",
                notCheckable = 1,
                func = function()
                    CloseWhisperTab(name)
                end,
            }, 1)
        end
    end

    hooksecurefunc("FriendsFrame_ShowDropdown", function(name)
        AddWhisperTabMenuEntry(name)
    end)

    hooksecurefunc("UnitPopup_OnClick", function()
        local menu = UIDROPDOWNMENU_OPEN_MENU
        if menu and (menu.which == "CHAT_ROSTER" or menu.which == "FRIEND") then
            AddWhisperTabMenuEntry(menu.name)
        end
    end)

    -- ========================================================================
    -- Метаданные
    -- ========================================================================
    NSQC4.SetModuleMeta("ui_whisper_tab", {
        label   = "Вкладка шепота",
        tooltip = "ПКМ по нику в чате → «В отдельную вкладку». Создаёт вкладку только для шепота с этим игроком.",
        order   = 240,
    })

end)