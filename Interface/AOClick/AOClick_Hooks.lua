-- ============================================================================
-- NSQC4 / Interface / AOClick / Hooks
-- Модуль ui_ao: AddMessage, MessageEventHandler, OnHyperlinkShow, меню.
-- ============================================================================

NSQC4.RegisterModule("ui_ao", function()

    local A = NSQC4.AOClick
    if not A then return end

    local aoSettings = A.aoSettings
    local CLASS_COLORS = A.CLASS_COLORS
    local aoNames = A.aoNames
    local GetGuildData = A.GetGuildData
    local ReplaceAll   = A.ReplaceAll
    local IsRelayText  = A.IsRelayText
    local ExtractLetter = A.ExtractLetter

    -- SetItemRef
    if not NSQC4._AOClick_SetItemRefPatched then
        NSQC4._AOClick_SetItemRefPatched = true
        local oldSetItemRef = SetItemRef
        SetItemRef = function(link, text, button, chatFrame)
            local raw = link or ""
            if raw == "nsqcofficer" or raw:match("^nsqcofficer:") or raw:match("^nsqcofficer$") then
                if button == "LeftButton" or button == nil then
                    A.OpenOfficerChat()
                end
                return
            end
            return oldSetItemRef(link, text, button, chatFrame)
        end
    end

    -- Меню по нику
    local menuFrame
    local function EnsureMenu()
        if menuFrame then return menuFrame end
        menuFrame = CreateFrame("Frame", "NSQC4AOClickMenu", UIParent, "UIDropDownMenuTemplate")
        return menuFrame
    end

    local function GetEditBoxForFrame(frame)
        if not frame then return ChatFrame1EditBox end
        local name = frame:GetName()
        if name then
            local eb = _G[name .. "EditBox"]
            if eb then return eb end
        end
        return ChatFrame1EditBox
    end
    A.GetEditBoxForFrame = GetEditBoxForFrame

    local function InsertNickToChat(name, frame)
        local eb = GetEditBoxForFrame(frame)
        if not eb then return end
        if not eb:IsShown() then eb:Show() end
        eb:Insert(name .. ", ")
        eb:SetFocus()
    end
    A.InsertNickToChat = InsertNickToChat

    local function GetFaction(name)
        local data = aoNames[name]
        if type(data) == "table" then return data.faction end
        return nil
    end

    local function MyFaction()
        return UnitFactionGroup("player")
    end

    local function Menu_Info(name)
        SendAddonMessage(A.PREFIX_Q, name, "GUILD")
    end

    local function Menu_Invite(name)
        local theirFaction = GetFaction(name)
        local mine = MyFaction()
        if theirFaction and mine and theirFaction ~= mine then
            print("|cffff0000[AOClick]|r " .. name .. " — другая фракция, приглашение невозможно.")
            return
        end
        InviteUnit(name)
    end

    local function ShowNickMenu(name)
        local m = EnsureMenu()
        m.name = name

        UIDropDownMenu_Initialize(m, function(self, level)
            local info = UIDropDownMenu_CreateInfo()
            info.text = "Инфо"
            info.notCheckable = true
            info.func = function() Menu_Info(self.name) end
            UIDropDownMenu_AddButton(info)

            local theirFaction = GetFaction(self.name)
            local mine = MyFaction()
            local sameFaction = (not theirFaction) or (not mine) or (theirFaction == mine)

            info = UIDropDownMenu_CreateInfo()
            if sameFaction then
                info.text = "Принять в пати"
                info.notCheckable = true
                info.func = function() Menu_Invite(self.name) end
            else
                info.text = "Принять в пати (другая фракция)"
                info.notCheckable = true
                info.disabled = true
            end
            UIDropDownMenu_AddButton(info)

            -- Пункт "Игнор" — вызывает отдельный модуль ui_ao_ignore
            info = UIDropDownMenu_CreateInfo()
            local clean = A.CleanName(self.name)
            local isIgnored = nsDbc4.settings.ignoreList[clean] and true or false
            info.text = isIgnored and "Убрать из игнора" or "Игнор"
            info.notCheckable = true
            info.func = function()
                if NSQC4.AOClick_Ignore_Toggle then
                    NSQC4.AOClick_Ignore_Toggle(self.name)
                end
            end
            UIDropDownMenu_AddButton(info)
        end, "MENU")

        ToggleDropDownMenu(1, nil, m, "cursor", 0, 0)
    end
    A.ShowNickMenu = ShowNickMenu

    -- AddMessage
    local InitFrame = CreateFrame("Frame")
    InitFrame:RegisterEvent("PLAYER_LOGIN")
    local hooksInstalled = false

    InitFrame:SetScript("OnEvent", function(self)
        if hooksInstalled then return end
        hooksInstalled = true
        self:UnregisterAllEvents()

        local function InstallAddMessageHook(chatFrame)
            if not chatFrame then return end
            local oldAddMessage = chatFrame.AddMessage
            chatFrame.AddMessage = function(self2, msg, ...)
                if msg and type(msg) == "string" then
                    msg = msg:gsub(
                        "%[([^%[%]:]+):([%d%-:]+)%]",
                        function(name, inner)
                            local nums = {}
                            for n in inner:gmatch("%-?%d+") do
                                nums[#nums + 1] = n
                            end
                            if #nums < 2 then
                                return "[" .. name .. ":" .. inner .. "]"
                            end

                            local level = nums[1]
                            local gp    = nums[2]
                            local rep   = nums[3]

                            local lv = tonumber(level)
                            if not lv or lv < 1 or lv > 80 then
                                return "[" .. name .. ":" .. inner .. "]"
                            end

                            local cleanName = name:match("^([^%-]+)") or name
                            local cacheRep = nsDbc4 and nsDbc4.reputation and nsDbc4.reputation[cleanName]
                            local repNum = rep or cacheRep

                            local lvNum = tonumber(level)
                            local gvNum = tonumber(gp)
                            local rvNum = repNum and tonumber(repNum) or nil

                            local hideL = aoSettings.hideLevel or lvNum == 80 or lvNum == 0
                            local hideG = aoSettings.hideGP    or gvNum == 0
                            local hideR = aoSettings.hideRep   or rvNum == 0 or rvNum == nil or rvNum == gvNum

                            local parts = {}
                            if not hideL then parts[#parts + 1] = level end
                            if not hideG then parts[#parts + 1] = gp    end
                            if not hideR then parts[#parts + 1] = tostring(repNum) end

                            if #parts == 0 then
                                return "[" .. name .. "]"
                            end
                            return "[" .. name .. ":" .. table.concat(parts, ":") .. "]"
                        end)

                    msg = msg:gsub(
                        "%[([^%[%]:]+):(%d+)%]",
                        function(name, gp)
                            local cleanName = name:match("^([^%-]+)") or name
                            local repNum = nsDbc4 and nsDbc4.reputation and nsDbc4.reputation[cleanName]
                            if repNum and tonumber(repNum) ~= 0 and not aoSettings.hideRep then
                                return "[" .. name .. ":" .. gp .. ":" .. tostring(repNum) .. "]"
                            end
                            return "[" .. name .. ":" .. gp .. "]"
                        end)

                    msg = msg:gsub(
                        "|Hplayer:([^|:]+)([:%d+]*)([^|]*)|h%[([^%]]+)%]|h",
                        function(name, extra, msgCnt, displayName)
                            local gd = GetGuildData(name)
                            local repNum = nsDbc4 and nsDbc4.reputation and nsDbc4.reputation[name]

                            local color = "|cffffffff"
                            if gd and gd.classFile and CLASS_COLORS[gd.classFile] then
                                color = CLASS_COLORS[gd.classFile]
                            end

                            local level = gd and gd.level
                            local gp    = gd and gd.gp

                            local lvNum = tonumber(level)
                            local gvNum = tonumber(gp)
                            local rvNum = repNum and tonumber(repNum) or nil

                            local hideL = aoSettings.hideLevel or lvNum == 80 or lvNum == 0
                            local hideG = aoSettings.hideGP    or gvNum == 0
                            local hideR = aoSettings.hideRep   or rvNum == 0 or rvNum == nil

                            if hideL then level = nil end
                            if hideG then gp    = nil end
                            if hideR then repNum = nil end

                            local parts = {}
                            if level then parts[#parts + 1] = tostring(level) end
                            if gp    then parts[#parts + 1] = tostring(gp)    end
                            if repNum and tonumber(repNum) ~= 0 then
                                parts[#parts + 1] = tostring(repNum)
                            end

                            local display = displayName
                            if #parts > 0 then
                                display = displayName .. ":" .. table.concat(parts, ":")
                            end

                            return "|Hplayer:" .. name .. "|h["
                                .. color .. display .. "]|r|h"
                        end)
                end
                return oldAddMessage(self2, msg, ...)
            end
        end

        for i = 1, NUM_CHAT_WINDOWS do
            InstallAddMessageHook(_G["ChatFrame"..i])
        end
        if DEFAULT_CHAT_FRAME then
            InstallAddMessageHook(DEFAULT_CHAT_FRAME)
        end

        if type(ChatFrame_MessageEventHandler) == "function" then
            local oldMessageHandler = ChatFrame_MessageEventHandler
            ChatFrame_MessageEventHandler = function(self2, event, ...)
                if event == "CHAT_MSG_GUILD" or event == "CHAT_MSG_OFFICER" then
                    local text = select(1, ...)
                    if text and IsRelayText(text) then
                        local letter = ExtractLetter(text)
                        local newText = ReplaceAll(text)
                        local tag, r, g, b
                        if event == "CHAT_MSG_GUILD" then
                            tag = A.GuildTag(letter)
                            r, g, b = A.GuildRGB()
                        else
                            tag = A.OfficerTag(letter)
                            r, g, b = A.OFFICER_R, A.OFFICER_G, A.OFFICER_B
                        end
                        self2:AddMessage(tag .. newText, r, g, b)
                        return
                    end
                end
                return oldMessageHandler(self2, event, ...)
            end
        end
    end)

    -- Клик по нику
    local oldOnHyperlinkShow = ChatFrame_OnHyperlinkShow
    ChatFrame_OnHyperlinkShow = function(self, link, text, button)
        local linkType, linkData = link:match("^(%a+):(.+)$")

        if linkType == "player" and linkData then
            local name = linkData:match("^([^:]+)")
            if name and aoNames[name] then
                if button == "LeftButton" then
                    InsertNickToChat(name, self)
                    return
                elseif button == "RightButton" then
                    ShowNickMenu(name)
                    return
                end
            end
        end

        return oldOnHyperlinkShow(self, link, text, button)
    end

end)