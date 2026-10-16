-- ============================================================================
-- NSQC4 / Interface / AOClick
-- ============================================================================

NSQC4.RegisterModule("ui_ao", function()

    local CLASS_COLORS = {
        ["1"] = "|cffC79C6E", ["2"] = "|cffF58CBA",
        ["3"] = "|cffABD473", ["4"] = "|cfffff569",
        ["5"] = "|cffffffff", ["6"] = "|cffC41F3B",
        ["7"] = "|cff0070DE", ["8"] = "|cff69CCF0",
        ["9"] = "|cff9482C9", ["0"] = "|cffFF7D0A",
    }

    local DEFAULT_COLOR    = "|cFFC0C0C0"
    local NICK_COLOR_RESET = "|r"
    local PREFIX_Q = "nsInfoQ"

    -- aoNames[name] = { faction = "Horde"/"Alliance" }
    -- Заполняется ТОЛЬКО для ретранслируемых ников
    local aoNames = {}

    local OFFICER_COLOR = "|cff00a000"
    local OFFICER_R, OFFICER_G, OFFICER_B = 0.00, 0.63, 0.00

    local function GuildRGB()
        local t = ChatTypeInfo and ChatTypeInfo["GUILD"]
        if t then return t.r or 0.25, t.g or 0.75, t.b or 0.25 end
        return 0.25, 0.75, 0.25
    end

    local function GuildTag(letter)
        return "|Hchannel:GUILD|h[G" .. (letter or "") .. "]|h"
    end

    local function OfficerTag(letter)
        return OFFICER_COLOR .. "|Hnsqcofficer|h[O" .. (letter or "") .. "]|h|r"
    end

    local function OpenOfficerChat()
        local eb = ChatFrame1EditBox
        if not eb then return end
        if not eb:IsShown() then eb:Show() end
        eb:SetText("/o ")
        eb:SetFocus()
    end

    if not NSQC4._AOClick_SetItemRefPatched then
        NSQC4._AOClick_SetItemRefPatched = true
        local oldSetItemRef = SetItemRef
        SetItemRef = function(link, text, button, chatFrame)
            local raw = link or ""
            if raw == "nsqcofficer"
               or raw:match("^nsqcofficer:")
               or raw:match("^nsqcofficer$") then
                if button == "LeftButton" or button == nil then
                    OpenOfficerChat()
                end
                return
            end
            return oldSetItemRef(link, text, button, chatFrame)
        end
    end

    local menuFrame

    local function EnsureMenu()
        if menuFrame then return menuFrame end
        local m = CreateFrame("Frame", "NSQC4AOClickMenu", UIParent, "UIDropDownMenuTemplate")
        menuFrame = m
        return m
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

    local function InsertNickToChat(name, frame)
        local eb = GetEditBoxForFrame(frame)
        if not eb then return end
        if not eb:IsShown() then eb:Show() end
        eb:Insert(name .. ", ")
        eb:SetFocus()
    end

    local function GetFaction(name)
        local data = aoNames[name]
        if type(data) == "table" then return data.faction end
        return nil
    end

    local function MyFaction()
        return UnitFactionGroup("player")
    end

    local function Menu_Info(name)
        SendAddonMessage(PREFIX_Q, name, "GUILD")
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
        end, "MENU")

        ToggleDropDownMenu(1, nil, m, "cursor", 0, 0)
    end

    -- Ссылку |Hplayer:...|h вешаем ТОЛЬКО на ретранслируемые ники
    local function BuildReplacement(code, nick, meta, faction)
        local cleanName = nick:gsub(":+$", "")
        local color = CLASS_COLORS[code] or DEFAULT_COLOR
        aoNames[cleanName] = { faction = faction }

        local nickDisplay = cleanName
        if meta and meta ~= "" then
            nickDisplay = cleanName .. meta
        end

        -- Здесь ссылка делается ВСЕГДА, потому что BuildReplacement вызывается только для релей-сообщений
        local nickLink = "|Hplayer:" .. cleanName .. "|h" ..
            color .. "[" .. nickDisplay .. "]" .. NICK_COLOR_RESET .. "|h"

        return nickLink .. ": "
    end

    local function ReplaceAll(msg)
        msg = msg:gsub(
            "%[\208\158(%d):(%-?%d+):(%-?%d+)%]%s+(%S+):%s*",
            function(code, level, rep, nick)
                if tonumber(level) == 80 then
                    return BuildReplacement(code, nick, ":" .. rep, "Horde")
                else
                    return BuildReplacement(code, nick, ":" .. level .. ":" .. rep, "Horde")
                end
            end)
        msg = msg:gsub(
            "%[\208\158(%d):(%-?%d+)%]%s+(%S+):%s*",
            function(code, rep, nick) return BuildReplacement(code, nick, ":" .. rep, "Horde") end)
        msg = msg:gsub(
            "%[\208\158(%d)%]%s+(%S+):%s*",
            function(code, nick) return BuildReplacement(code, nick, nil, "Horde") end)

        msg = msg:gsub(
            "%[\208\144(%d):(%-?%d+):(%-?%d+)%]%s+(%S+):%s*",
            function(code, level, rep, nick)
                if tonumber(level) == 80 then
                    return BuildReplacement(code, nick, ":" .. rep, "Alliance")
                else
                    return BuildReplacement(code, nick, ":" .. level .. ":" .. rep, "Alliance")
                end
            end)
        msg = msg:gsub(
            "%[\208\144(%d):(%-?%d+)%]%s+(%S+):%s*",
            function(code, rep, nick) return BuildReplacement(code, nick, ":" .. rep, "Alliance") end)
        msg = msg:gsub(
            "%[\208\144(%d)%]%s+(%S+):%s*",
            function(code, nick) return BuildReplacement(code, nick, nil, "Alliance") end)

        msg = msg:gsub(
            "%[O(%d):(%-?%d+):(%-?%d+)%]%s+(%S+):%s*",
            function(code, level, rep, nick)
                if tonumber(level) == 80 then
                    return BuildReplacement(code, nick, ":" .. rep, "Horde")
                else
                    return BuildReplacement(code, nick, ":" .. level .. ":" .. rep, "Horde")
                end
            end)
        msg = msg:gsub(
            "%[O(%d):(%-?%d+)%]%s+(%S+):%s*",
            function(code, rep, nick) return BuildReplacement(code, nick, ":" .. rep, "Horde") end)
        msg = msg:gsub(
            "%[O(%d)%]%s+(%S+):%s*",
            function(code, nick) return BuildReplacement(code, nick, nil, "Horde") end)

        msg = msg:gsub(
            "%[A(%d):(%-?%d+):(%-?%d+)%]%s+(%S+):%s*",
            function(code, level, rep, nick)
                if tonumber(level) == 80 then
                    return BuildReplacement(code, nick, ":" .. rep, "Alliance")
                else
                    return BuildReplacement(code, nick, ":" .. level .. ":" .. rep, "Alliance")
                end
            end)
        msg = msg:gsub(
            "%[A(%d):(%-?%d+)%]%s+(%S+):%s*",
            function(code, rep, nick) return BuildReplacement(code, nick, ":" .. rep, "Alliance") end)
        msg = msg:gsub(
            "%[A(%d)%]%s+(%S+):%s*",
            function(code, nick) return BuildReplacement(code, nick, nil, "Alliance") end)

        return msg
    end

    local function IsRelayText(text)
        if not text or text == "" then return false end
        if text:match("^%[\208\158") then return true end
        if text:match("^%[\208\144") then return true end
        if text:match("^%[O")        then return true end
        if text:match("^%[A")        then return true end
        return false
    end

    local function ExtractLetter(text)
        if text:match("^%[\208\158") then return "О" end
        if text:match("^%[\208\144") then return "А" end
        if text:match("^%[O")        then return "О" end
        if text:match("^%[A")        then return "А" end
        return ""
    end

    local function ReplaceChannelPrefix(msg)
        msg = msg:gsub("|Hchannel:GUILD|h%[\208\147\208\184\208\187\209\140\208\180\208\184\209\143%]|h%s*",   GuildTag())
        msg = msg:gsub("|Hchannel:GUILD|h%[\195\232\235\252\228\232\255%]|h%s*",                                GuildTag())
        msg = msg:gsub("|Hchannel:OFFICER|h%[\208\158\209\132\208\184\209\134\208\181\209\128%]|h%s*",         OfficerTag())
        msg = msg:gsub("|Hchannel:OFFICER|h%[\206\244\232\246\229\240%]|h%s*",                                  OfficerTag())
        return msg
    end

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
                    msg = ReplaceChannelPrefix(msg)
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
                    if IsRelayText(text) then
                        local letter = ExtractLetter(text)
                        local newText = ReplaceAll(text)
                        local tag
                        local r, g, b
                        if event == "CHAT_MSG_GUILD" then
                            tag = GuildTag(letter)
                            r, g, b = GuildRGB()
                        else
                            tag = OfficerTag(letter)
                            r, g, b = OFFICER_R, OFFICER_G, OFFICER_B
                        end
                        self2:AddMessage(tag .. newText, r, g, b)
                        return
                    end
                end
                return oldMessageHandler(self2, event, ...)
            end
        end
    end)

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