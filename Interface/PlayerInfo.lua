-- ============================================================================
-- NSQC4 / Interface / PlayerInfo
-- ПКМ по нику в чате → «Посмотреть информацию».
-- Вывод в офицерский чат. Модуль: ui_player_info.
-- ============================================================================

NSQC4.RegisterModule("ui_player_info", function()

    -- ========================================================================
    -- Получение и вывод информации об игроке
    -- ========================================================================
    local function ShowPlayerInfo(playerName)
        if not playerName or playerName == "" then return end

        local officerNote, publicNote, rank, level, zone, className, found = "", "", "", "", "", "", false

        for i = 1, GetNumGuildMembers() do
            local name, rankName, _, levelVal, class, zoneName, pubNote, offNote = GetGuildRosterInfo(i)
            if name and strsplit("-", name) == playerName then
                publicNote, officerNote, rank, level, zone, className, found =
                    pubNote or "", offNote or "", rankName or "", levelVal or "", zoneName or "", class or "", true
                break
            end
        end

        if found then
            SendChatMessage(
                "Информация: " .. playerName ..
                " || Звание: " .. (rank ~= "" and rank or "-") ..
                " || Уровень: " .. (level ~= "" and level or "-") ..
                " || Класс: " .. (className ~= "" and className or "-") ..
                " || Зона: " .. (zone ~= "" and zone or "-"),
                "OFFICER")

            SendChatMessage(
                "Заметки: офиц. - " .. (officerNote ~= "" and officerNote or "-") ..
                " || публ. - " .. (publicNote ~= "" and publicNote or "-"),
                "OFFICER")

            SendChatMessage("\"репутация " .. playerName, "GUILD")
        else
            SendChatMessage("Игрок " .. playerName .. " не найден в гильдии.", "OFFICER")
        end
    end

    -- ========================================================================
    -- Создание отдельной вкладки для шепота с фильтром
    -- ========================================================================
    local function MoveToSeparateTab(playerName)
        if not playerName or playerName == "" then return end

        local tabName = "Шепот: " .. playerName

        -- Проверяем, не открыта ли уже вкладка с таким именем
        for i = 1, NUM_CHAT_WINDOWS do
            local f = _G["ChatFrame"..i]
            if f and f.name == tabName then
                -- Если уже есть, просто делаем её активной
                FCF_DockFrame(f)
                FCF_SelectDockFrame(f)
                return
            end
        end

        -- Создаем новую
        local chatFrame = FCF_OpenNewWindow(tabName)
        
        if chatFrame then
            -- Принудительно докируем её к основной панели, чтобы не было наслаивания
            FCF_DockFrame(chatFrame)
            -- Делаем её активной (переключаемся на неё)
            FCF_SelectDockFrame(chatFrame)

            -- Фильтруем входящие шепоты
            ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", function(self, event, msg, author, ...)
                if self == chatFrame and author == playerName then
                    return false -- Показать
                elseif self == chatFrame then
                    return true -- Скрыть
                end
                return false
            end)
            
            -- Фильтруем исходящие шепоты
            ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", function(self, event, msg, author, ...)
                if self == chatFrame and author == playerName then
                    return false 
                elseif self == chatFrame then
                    return true
                end
                return false
            end)

            print("|cff00ff00[NSQC4]|r Создана вкладка " .. tabName)
        end
    end

    -- ========================================================================
    -- Хук на контекстное меню: добавление пунктов
    -- ========================================================================
    local function AddInfoMenuEntry(name)
        if not name or name == UNKNOWNOBJECT then return end

        -- Пункт «В отдельную вкладку»
        UIDropDownMenu_AddButton({
            text = "В отдельную вкладку",
            notCheckable = 1,
            func = function()
                MoveToSeparateTab(name)
            end,
        }, 1)

        -- Пункт «Посмотреть информацию»
        UIDropDownMenu_AddButton({
            text = "Посмотреть информацию",
            notCheckable = 1,
            func = function()
                ShowPlayerInfo(name)
            end,
        }, 1)
    end

    hooksecurefunc("FriendsFrame_ShowDropdown", function(name)
        AddInfoMenuEntry(name)
    end)

    hooksecurefunc("UnitPopup_OnClick", function()
        local menu = UIDROPDOWNMENU_OPEN_MENU
        if menu and (menu.which == "CHAT_ROSTER" or menu.which == "FRIEND") then
            AddInfoMenuEntry(menu.name)
        end
    end)

    -- ========================================================================
    -- Метаданные модуля ui_player_info
    -- ========================================================================
    NSQC4.SetModuleMeta("ui_player_info", {
        label   = "Инфо об игроке",
        tooltip = "ПКМ по нику в чате → «Посмотреть информацию». Вывод в офицерский чат.",
        order   = 220,
    })

end)