-- ============================================================================
-- NSQC4 / Interface / AOClick
-- Кликабельные ники из канала АО + отображение уровень:ГП:репа для гильдейцев.
-- ============================================================================

NSQC4.RegisterModule("ui_ao", function()

    local CLASS_COLORS = {
        ["WARRIOR"] = "|cffC79C6E",  ["PALADIN"] = "|cffF58CBA",
        ["HUNTER"] = "|cffABD473",   ["ROGUE"] = "|cfffff569",
        ["PRIEST"] = "|cffffffff",   ["DEATHKNIGHT"] = "|cffC41F3B",
        ["SHAMAN"] = "|cff0070DE",   ["MAGE"] = "|cff69CCF0",
        ["WARLOCK"] = "|cff9482C9",  ["DRUID"] = "|cffFF7D0A",
        ["1"] = "|cffC79C6E", ["2"] = "|cffF58CBA", ["3"] = "|cffABD473",
        ["4"] = "|cfffff569", ["5"] = "|cffffffff", ["6"] = "|cffC41F3B",
        ["7"] = "|cff0070DE", ["8"] = "|cff69CCF0", ["9"] = "|cff9482C9",
        ["0"] = "|cffFF7D0A",
    }

    local DEFAULT_COLOR    = "|cFFC0C0C0"
    local NICK_COLOR_RESET = "|r"
    local PREFIX_Q = "nsInfoQ"

    nsDbc4 = nsDbc4 or {}
    nsDbc4.settings = nsDbc4.settings or {}
    nsDbc4.settings.aoClick = nsDbc4.settings.aoClick or {
        hideLevel = false,
        hideGP    = false,
        hideRep   = false,
    }
    local aoSettings = nsDbc4.settings.aoClick
    if aoSettings.hideRep == nil then aoSettings.hideRep = false end

    -- aoNames[name] = { faction = "Horde"/"Alliance" } — только для релея АО
    local aoNames = {}

    -- guildInfo[name] = { level, gp, classFile, onote }
    local guildInfo = {}

    local OFFICER_COLOR = "|cff00a000"
    local OFFICER_R, OFFICER_G, OFFICER_B = 0.00, 0.63, 0.00

    -- ========================================================================
    -- Гильд-ростер
    -- ========================================================================
    local function mysplit(inputstr, sep)
        if sep == nil then sep = "%s" end
        local t = {}
        for str in string.gmatch(inputstr or "", "([^" .. sep .. "]+)") do
            table.insert(t, str)
        end
        return t
    end

    local function RebuildGuildInfo()
        guildInfo = {}
        if not IsInGuild() then return end
        local n = GetNumGuildMembers(true)
        if not n or n == 0 then return end
        for i = 1, n do
            local name, _, _, level, _, _, _, officerNote, _, _, classFile = GetGuildRosterInfo(i)
            if name then
                local cleanName = name:match("^([^%-]+)") or name
                local words = mysplit(officerNote or "")
                guildInfo[cleanName] = {
                    level     = level,
                    gp        = words[3],
                    classFile = classFile,
                    onote     = officerNote,
                }
            end
        end
    end

    local function RequestGuildRoster()
        if not IsInGuild() then return end
        GuildRoster()
    end

    local function GetGuildData(name)
        if not name then return nil end
        local cleanName = name:match("^([^%-]+)") or name
        return guildInfo[cleanName]
    end

    -- ========================================================================
    -- Каналы
    -- ========================================================================
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

    -- ========================================================================
    -- Меню по нику (для АО)
    -- ========================================================================
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

    -- ========================================================================
    -- Релей АО
    -- ========================================================================
    local function BuildRelayReplacement(code, nick, meta, faction)
        local cleanName = nick:gsub(":+$", "")
        local color = CLASS_COLORS[code] or DEFAULT_COLOR
        aoNames[cleanName] = { faction = faction }

        local nickDisplay = cleanName
        if meta and meta ~= "" then
            nickDisplay = cleanName .. meta
        end

        local nickLink = "|Hplayer:" .. cleanName .. "|h" ..
            color .. "[" .. nickDisplay .. "]" .. NICK_COLOR_RESET .. "|h"

        return nickLink .. ": "
    end

    local function ReplaceAll(msg)
        msg = msg:gsub(
            "%[\208\158(%d):(%-?%d+):(%-?%d+)%]%s+(%S+):%s*",
            function(code, level, rep, nick)
                if tonumber(level) == 80 then
                    return BuildRelayReplacement(code, nick, ":" .. rep, "Horde")
                else
                    return BuildRelayReplacement(code, nick, ":" .. level .. ":" .. rep, "Horde")
                end
            end)
        msg = msg:gsub(
            "%[\208\158(%d):(%-?%d+)%]%s+(%S+):%s*",
            function(code, rep, nick) return BuildRelayReplacement(code, nick, ":" .. rep, "Horde") end)
        msg = msg:gsub(
            "%[\208\158(%d)%]%s+(%S+):%s*",
            function(code, nick) return BuildRelayReplacement(code, nick, nil, "Horde") end)

        msg = msg:gsub(
            "%[\208\144(%d):(%-?%d+):(%-?%d+)%]%s+(%S+):%s*",
            function(code, level, rep, nick)
                if tonumber(level) == 80 then
                    return BuildRelayReplacement(code, nick, ":" .. rep, "Alliance")
                else
                    return BuildRelayReplacement(code, nick, ":" .. level .. ":" .. rep, "Alliance")
                end
            end)
        msg = msg:gsub(
            "%[\208\144(%d):(%-?%d+)%]%s+(%S+):%s*",
            function(code, rep, nick) return BuildRelayReplacement(code, nick, ":" .. rep, "Alliance") end)
        msg = msg:gsub(
            "%[\208\144(%d)%]%s+(%S+):%s*",
            function(code, nick) return BuildRelayReplacement(code, nick, nil, "Alliance") end)

        msg = msg:gsub(
            "%[O(%d):(%-?%d+):(%-?%d+)%]%s+(%S+):%s*",
            function(code, level, rep, nick)
                if tonumber(level) == 80 then
                    return BuildRelayReplacement(code, nick, ":" .. rep, "Horde")
                else
                    return BuildRelayReplacement(code, nick, ":" .. level .. ":" .. rep, "Horde")
                end
            end)
        msg = msg:gsub(
            "%[O(%d):(%-?%d+)%]%s+(%S+):%s*",
            function(code, rep, nick) return BuildRelayReplacement(code, nick, ":" .. rep, "Horde") end)
        msg = msg:gsub(
            "%[O(%d)%]%s+(%S+):%s*",
            function(code, nick) return BuildRelayReplacement(code, nick, nil, "Horde") end)

        msg = msg:gsub(
            "%[A(%d):(%-?%d+):(%-?%d+)%]%s+(%S+):%s*",
            function(code, level, rep, nick)
                if tonumber(level) == 80 then
                    return BuildRelayReplacement(code, nick, ":" .. rep, "Alliance")
                else
                    return BuildRelayReplacement(code, nick, ":" .. level .. ":" .. rep, "Alliance")
                end
            end)
        msg = msg:gsub(
            "%[A(%d):(%-?%d+)%]%s+(%S+):%s*",
            function(code, rep, nick) return BuildRelayReplacement(code, nick, ":" .. rep, "Alliance") end)
        msg = msg:gsub(
            "%[A(%d)%]%s+(%S+):%s*",
            function(code, nick) return BuildRelayReplacement(code, nick, nil, "Alliance") end)

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

    -- ========================================================================
    -- Гильдейцы: |Hplayer:Имя|h[Имя]|h → |Hplayer:Имя|h[Имя:lvl:gp:rep]|h
    -- rep берётся из кэша nsDbc4.reputation (AOReputation.lua).
    -- ========================================================================
    local function BuildGuildDisplay(cleanName, displayName)
        local gd = GetGuildData(cleanName)

        local level = gd and gd.level
        local gp    = gd and gd.gp
        local rep   = nil

        -- Репутация — из кэша AOReputation
        if nsDbc4 and nsDbc4.reputation then
            rep = nsDbc4.reputation[cleanName]
        end

        -- Скрыть 80-й уровень
        if level == 80 or level == "80" then level = nil end

        -- Скрыть нулевые значения (как будто галочка снята)
        if level == 0 or level == "0" then level = nil end
        if gp    == 0 or gp    == "0" then gp    = nil end
        if rep   == 0 or rep   == "0" then rep   = nil end

        -- Пользовательские галочки
        if aoSettings.hideLevel then level = nil end
        if aoSettings.hideGP    then gp    = nil end
        if aoSettings.hideRep   then rep   = nil end

        if level ~= nil then level = tostring(level); if level == "" then level = nil end end
        if gp    ~= nil then gp    = tostring(gp);    if gp    == "" then gp    = nil end end
        if rep   ~= nil then rep   = tostring(rep);   if rep   == "" then rep   = nil end end

        local display = displayName
        local parts = {}
        if level then parts[#parts + 1] = level end
        if gp    then parts[#parts + 1] = gp    end
        if rep   then parts[#parts + 1] = rep   end
        if #parts > 0 then
            display = displayName .. ":" .. table.concat(parts, ":")
        end

        local color = "|cffffffff"
        if gd and gd.classFile and CLASS_COLORS[gd.classFile] then
            color = CLASS_COLORS[gd.classFile]
        end

        return color, display
    end

    -- ========================================================================
    -- Перехват AddMessage
    -- ========================================================================
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
                    -- Гильдейцы: |Hplayer:Имя|h[Имя]|h → с суффиксом
                    if next(guildInfo) then
                        msg = msg:gsub(
                            "|Hplayer:([^|:]+)([:%d+]*)([^|]*)|h%[([^%]]+)%]|h",
                            function(name, extra, msgCnt, displayName)
                                local color, display = BuildGuildDisplay(name, displayName)
                                -- Не тащим extra/msgCnt из оригинала: они могут
                                -- содержать мусорные :0:0. Собираем заново.
                                return "|Hplayer:" .. name .. "|h["
                                            .. color .. display .. "]|r|h"
                            end)
                    end
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

        -- Релей АО: только для сообщений, начинающихся с [О/[А/[O/[A
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

    -- ========================================================================
    -- Клик по нику
    -- ========================================================================
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

    -- ========================================================================
    -- Ростер
    -- ========================================================================
    local rosterFrame = CreateFrame("Frame")
    rosterFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
    rosterFrame:RegisterEvent("PLAYER_GUILD_UPDATE")
    rosterFrame:SetScript("OnEvent", function(_, event)
        if event == "GUILD_ROSTER_UPDATE" then
            RebuildGuildInfo()
        elseif event == "PLAYER_GUILD_UPDATE" then
            guildInfo = {}
            if IsInGuild() then
                RebuildGuildInfo()
                RequestGuildRoster()
            end
        end
    end)

    if IsInGuild() then
        RebuildGuildInfo()
        RequestGuildRoster()
    end

    -- ========================================================================
    -- Настройки
    -- ========================================================================
    local settingsFrame

    local function OpenAOClickSettings()
        if not settingsFrame then
            local f = CreateFrame("Frame", "NSQC4AOClickSettings", UIParent)
            f:SetSize(400, 260)
            f:SetPoint("CENTER")
            f:SetFrameStrata("TOOLTIP")
            f:SetToplevel(true)
            f:SetFrameLevel(100)
            f:SetBackdrop({
                bgFile   = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 8, edgeSize = 12,
                insets = { left = 3, right = 3, top = 3, bottom = 3 },
            })
            f:SetBackdropColor(0, 0, 0, 1)
            f:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

            local t = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
            t:SetPoint("TOPLEFT", 12, -12)
            t:SetText("Настройки: Ссылки АО")

            local function mkCB(y, key, text)
                local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
                cb:SetPoint("TOPLEFT", 12, y)
                cb:SetSize(24, 24)
                local fs = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                fs:SetPoint("LEFT", cb, "RIGHT", 4, 0)
                fs:SetText(text)
                cb:SetChecked(aoSettings[key] and true or false)
                cb:SetScript("OnClick", function(self)
                    aoSettings[key] = self:GetChecked() and true or false
                end)
                return cb
            end

            mkCB(-42,  "hideLevel", "Скрыть уровень")
            mkCB(-70,  "hideGP",    "Скрыть ГП")
            mkCB(-98,  "hideRep",   "Скрыть репу")

            local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
            close:SetSize(100, 24)
            close:SetPoint("BOTTOMRIGHT", -10, 10)
            close:SetText("Закрыть")
            close:SetScript("OnClick", function() f:Hide() end)

            f:SetMovable(true)
            f:EnableMouse(true)
            f:RegisterForDrag("LeftButton")
            f:SetScript("OnDragStart", f.StartMoving)
            f:SetScript("OnDragStop",  f.StopMovingOrSizing)

            settingsFrame = f
        end
        settingsFrame:SetFrameStrata("TOOLTIP")
        settingsFrame:Show()
        settingsFrame:Raise()
    end

    if NSQC4.RegisterModuleSettings then
        NSQC4.RegisterModuleSettings("ui_ao", OpenAOClickSettings)
    end

    NSQC4.SetModuleMeta("ui_ao", {
        label   = "Ссылки АО",
        tooltip = "Кликабельные ники из канала АО; у гильдейцев отображается уровень:ГП:репа.",
        order   = 190,
    })

end)