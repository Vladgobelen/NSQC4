-- ============================================================================
-- NSQC4 / Interface / ListUI
-- Окно управления списком алертов: ник → звук. Модуль "ui_list".
-- ============================================================================

NSQC4 = NSQC4 or {}

-- ============================================================================
-- Список звуков (пути обновлены на NSQC4)
-- ============================================================================
ns_alert_sounds = {
    {
        label = "Системные",
        sounds = {
            "Sound\\Interface\\AlarmClockWarning1.wav",
            "Sound\\Interface\\AlarmClockWarning2.wav",
            "Sound\\Interface\\AlarmClockWarning3.wav",
            "Sound\\Interface\\AchievementMenuOpen.wav",
            "Sound\\Interface\\AchievementMenuClose.wav",
            "Sound\\Interface\\AuctionWindowOpen.wav",
            "Sound\\Interface\\AuctionWindowClose.wav",
            "Sound\\Interface\\MapPing.wav",
            "Sound\\Interface\\ReadyCheck.wav",
            "Sound\\Interface\\RaidWarning.wav",
            "Sound\\Interface\\LevelUp.wav",
            "Sound\\Interface\\LFG_RoleCheck.wav",
            "Sound\\Interface\\LFG_Denied.wav",
            "Sound\\Interface\\LFG_Rewards.wav",
            "Sound\\Interface\\GuildVaultOpen.wav",
            "Sound\\Interface\\GuildVaultClose.wav",
            "Sound\\Interface\\TalentScreenOpen.wav",
            "Sound\\Interface\\TalentScreenClose.wav",
            "Sound\\Spells\\SimonGame_Visual_GameStart.wav",
            "Sound\\Spells\\PVPEnterQueue.wav",
            "Sound\\Spells\\PVPFlagTaken.wav",
            "Sound\\Spells\\PVPFlagCaptured.wav",
            "Sound\\Spells\\PVPFlagReturned.wav",
            "Sound\\Spells\\ShaysBell.wav",
            "Sound\\Doodad\\BellTollAlliance.wav",
            "Sound\\Doodad\\BellTollHorde.wav",
            "Sound\\Doodad\\BellTollNightElf.wav",
            "Sound\\Doodad\\BoatDockedWarning.wav",
            "Sound\\Doodad\\G_NecropolisWound.wav",
            "Sound\\Doodad\\Goblin_Lottery_Open01.wav",
            "Sound\\Doodad\\Goblin_Lottery_Open02.wav",
            "Sound\\Doodad\\Goblin_Lottery_Open03.wav",
            "Sound\\Doodad\\Goblin_Lottery_Open04.wav",
            "Sound\\Event Sounds\\Event_wardrum_ogre.wav",
            "Sound\\Event Sounds\\Wisp\\WispPissed1.wav",
            "Sound\\Event Sounds\\Wisp\\WispPissed2.wav",
            "Sound\\Event Sounds\\Wisp\\WispPissed3.wav",
        },
    },
    {
        label = "Пользовательские",
        sounds = {
            "Interface\\AddOns\\NSQC4\\Media\\Sounds\\fls.mp3",
            "Interface\\AddOns\\NSQC4\\Media\\Sounds\\ach.ogg",
            "Interface\\AddOns\\NSQC4\\Media\\Sounds\\bbbb.ogg",
            "Interface\\AddOns\\NSQC4\\Media\\Sounds\\bt.ogg",
            "Interface\\AddOns\\NSQC4\\Media\\Sounds\\clc.ogg",
            "Interface\\AddOns\\NSQC4\\Media\\Sounds\\f.ogg",
            "Interface\\AddOns\\NSQC4\\Media\\Sounds\\gob.ogg",
            "Interface\\AddOns\\NSQC4\\Media\\Sounds\\gom.ogg",
            "Interface\\AddOns\\NSQC4\\Media\\Sounds\\hs.ogg",
            "Interface\\AddOns\\NSQC4\\Media\\Sounds\\k.ogg",
            "Interface\\AddOns\\NSQC4\\Media\\Sounds\\m.ogg",
            "Interface\\AddOns\\NSQC4\\Media\\Sounds\\ms.ogg",
            "Interface\\AddOns\\NSQC4\\Media\\Sounds\\mx.ogg",
            "Interface\\AddOns\\NSQC4\\Media\\Sounds\\sh.ogg",
            "Interface\\AddOns\\NSQC4\\Media\\Sounds\\smg.ogg",
            "Interface\\AddOns\\NSQC4\\Media\\Sounds\\t.ogg",
            "Interface\\AddOns\\NSQC4\\Media\\Sounds\\tr.ogg",
            "Interface\\AddOns\\NSQC4\\Media\\Sounds\\tx.ogg",
            "Interface\\AddOns\\NSQC4\\Media\\Sounds\\uz.ogg",
            "Interface\\AddOns\\NSQC4\\Media\\Sounds\\kare.mp3",
            "Interface\\AddOns\\NSQC4\\Media\\Sounds\\karg.mp3",
            "Interface\\AddOns\\NSQC4\\Media\\Sounds\\karp.mp3",
            "Interface\\AddOns\\NSQC4\\Media\\Sounds\\yaix.mp3",
            "Interface\\AddOns\\NSQC4\\Media\\Sounds\\yaiz.mp3",
        },
    },
}

local function GetFileName(path)
    return path:match("[^\\/]+$") or path
end

local function InitModule()
    if not NSQC4.Settings.IsModuleEnabled("ui_list") then return end

    local ListFrame = nil

    -- ========================================================================
    -- Создание / показ окна
    -- ========================================================================
    function NSQC4.ListUI_Show()
        if ListFrame then
            ListFrame:Show()
            ListFrame.UpdateList()
            return
        end

        local frame = CreateFrame("Frame", "NSQC4ListFrame", UIParent)
        ListFrame = frame
        frame:SetSize(400, 500)
        frame:SetPoint("CENTER")
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })

        local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", -5, -5)
        closeButton:SetScript("OnClick", function() frame:Hide() end)

        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", 0, -20)
        title:SetText("Управление списком")

        local editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
        editBox:SetSize(200, 30)
        editBox:SetPoint("TOP", 0, -60)
        editBox:SetAutoFocus(false)

        local addButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        addButton:SetSize(100, 30)
        addButton:SetPoint("TOPLEFT", editBox, "BOTTOMLEFT", 0, -20)
        addButton:SetText("Добавить")

        local delButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        delButton:SetSize(100, 30)
        delButton:SetPoint("TOPRIGHT", editBox, "BOTTOMRIGHT", 0, -20)
        delButton:SetText("Удалить")

        local scrollFrame = CreateFrame("ScrollFrame", "NSQC4ListScrollFrame", frame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetSize(360, 300)
        scrollFrame:SetPoint("TOP", addButton, "BOTTOM", 0, -30)

        local scrollBar = _G["NSQC4ListScrollFrameScrollBar"]
        if scrollBar then
            scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 32, -16)
        end

        local content = CreateFrame("Frame", nil, scrollFrame)
        content:SetSize(335, 0)
        scrollFrame:SetScrollChild(content)

        -- Локальные таблицы (вместо testQ.fls)
        local store = nsDbc4.settings.timer.sounds   -- хранилище: [ник] = путь к звуку

        content.entries = {}

        function frame:UpdateList()
            local totalHeight = 0

            for _, entry in ipairs(content.entries) do
                entry:Hide()
            end
            content.entries = content.entries or {}

            local names = {}
            for name in pairs(store) do
                table.insert(names, name)
            end
            table.sort(names, function(a, b) return a < b end)

            for i, name in ipairs(names) do
                local sound = store[name]
                local entry = content.entries[i]

                if not entry then
                    entry = CreateFrame("Frame", nil, content)
                    entry:SetSize(335, 20)

                    entry.text = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    entry.text:SetPoint("LEFT", 5, 0)
                    entry.text:SetWidth(200)

                    entry.dropdown = CreateFrame("Frame", "NSQC4ListDropDown"..i, entry, "UIDropDownMenuTemplate")
                    entry.dropdown:SetPoint("RIGHT", entry, "RIGHT", -10, 0)
                    entry.dropdown:SetWidth(120)

                    local button = _G["NSQC4ListDropDown"..i.."Button"]
                    button:SetScript("OnClick", function(self)
                        ToggleDropDownMenu(1, nil, entry.dropdown, self, 0, 0)
                    end)

                    local dropDownText = _G["NSQC4ListDropDown"..i.."Text"]
                    if dropDownText then
                        dropDownText:SetWidth(150)
                    end

                    UIDropDownMenu_Initialize(entry.dropdown, function(self, level)
                        if not level then return end

                        if level == 1 then
                            for _, category in ipairs(ns_alert_sounds) do
                                local info = UIDropDownMenu_CreateInfo()
                                info.text = category.label
                                info.value = category
                                info.hasArrow = true
                                info.notCheckable = true
                                UIDropDownMenu_AddButton(info, level)
                            end
                        elseif level == 2 then
                            local category = UIDROPDOWNMENU_MENU_VALUE
                            if category and category.sounds then
                                for _, soundPath in ipairs(category.sounds) do
                                    local info = UIDropDownMenu_CreateInfo()
                                    info.text = GetFileName(soundPath)
                                    info.value = soundPath
                                    info.func = function()
                                        store[entry.name] = soundPath
                                        UIDropDownMenu_SetText(entry.dropdown, GetFileName(soundPath))
                                        PlaySoundFile(soundPath, "Master")
                                        CloseDropDownMenus()
                                    end
                                    info.checked = (store[entry.name] == soundPath)
                                    UIDropDownMenu_AddButton(info, level)
                                end
                            end
                        end
                    end)

                    content.entries[i] = entry
                end

                entry.name = name
                entry.text:SetText(name)

                if sound then
                    UIDropDownMenu_SetText(entry.dropdown, GetFileName(sound))
                else
                    UIDropDownMenu_SetText(entry.dropdown, "Не выбрано")
                end

                entry:SetPoint("TOPLEFT", 5, -totalHeight)
                entry:Show()

                totalHeight = totalHeight + 20
            end

            for i = #names + 1, #content.entries do
                content.entries[i]:Hide()
            end

            content:SetHeight(math.max(totalHeight, 1))
            scrollFrame:UpdateScrollChildRect()
            if scrollBar then scrollBar:SetValue(0) end
        end

        addButton:SetScript("OnClick", function()
            local text = editBox:GetText()
            if text ~= "" and not store[text] then
                store[text] = "Interface\\AddOns\\NSQC4\\Media\\Sounds\\fls.mp3"
                frame:UpdateList()
                editBox:SetText("")
                editBox:ClearFocus()
            end
        end)

        delButton:SetScript("OnClick", function()
            local text = editBox:GetText()
            if text ~= "" and store[text] then
                store[text] = nil
                frame:UpdateList()
                editBox:SetText("")
                editBox:ClearFocus()
            end
        end)

        frame:UpdateList()
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, addon)
    if addon ~= "NSQC4" then return end
    self:UnregisterEvent("ADDON_LOADED")
    InitModule()
end)