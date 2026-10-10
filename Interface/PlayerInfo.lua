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
    -- Хук на контекстное меню: пункт «Посмотреть информацию»
    -- ========================================================================
    local function AddInfoMenuEntry(name)
        if not name or name == UNKNOWNOBJECT then return end
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

end)