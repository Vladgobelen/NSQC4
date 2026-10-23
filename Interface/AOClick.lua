-- ============================================================================
-- NSQC4 / Interface / AOClick
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
    }
    local aoSettings = nsDbc4.settings.aoClick

    local aoNames   = {}
    local guildInfo = {}

    local OFFICER_COLOR = "|cff00a000"
    local OFFICER_R, OFFICER_G, OFFICER_B = 0.00, 0.63, 0.00

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
            local name, _, _, level, _, _, note, officerNote, _, _, classFile = GetGuildRosterInfo(i)
            if name then
                local cleanName = name:match("^([^%-]+)") or name
                local words = mysplit(officerNote or "")
                guildInfo[cleanName] = {
                    level     = level,
                    gp        = words[3],
                    classFile = classFile,
                    note      = note,
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
            if raw == "nsqcofficer" or raw:match("^nsqcofficer:") or raw:match("^nsqcofficer$") then
                if button == "LeftButton" or button == nil then OpenOfficerChat() end
                return
            end
            return oldSetItemRef(link, text, button, chatFrame)
        end
    end

    local function ParseMeta(meta)
        if not meta or meta == "" then return nil, nil end
        local parts = {}
        for p in meta:gmatch("[^:]+") do
            parts[#parts + 1] = p
        end
        if #parts == 1 then
            return nil, parts[1]
        elseif #parts >= 2 then
            return parts[1], parts[2]
        end
        return nil, nil
    end

    -- Сборка ника для релея (сохраняем старую логику)
    local function BuildReplacement(code, nick, meta, faction)
        local cleanName = nick:gsub(":+$", "")
        local color = CLASS_COLORS[code] or DEFAULT_COLOR

        if faction then
            aoNames[cleanName] = { faction = faction }
        end

        local level, rep = ParseMeta(meta)

        if not level and not rep then
            local gd = GetGuildData(cleanName)
            if gd then
                level = gd.level
                rep   = gd.gp
            end
        end

        if level == 80 or level == "80" then level = nil end
        if aoSettings.hideLevel then level = nil end
        if aoSettings.hideGP    then rep   = nil end

        if level ~= nil then level = tostring(level); if level == "" then level = nil end end
        if rep   ~= nil then rep   = tostring(rep);   if rep   == "" then rep   = nil end end

        local display = cleanName
        if level and rep then
            display = cleanName .. ":" .. level .. ":" .. rep
        elseif rep then
            display = cleanName .. ":" .. rep
        elseif level then
            display = cleanName .. ":" .. level
        end

        return "|Hplayer:" .. cleanName .. "|h" ..
               color .. "[" .. display .. "]" .. NICK_COLOR_RESET .. "|h" .. ": "
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

    -- ========================================================================
    -- Подмена строки гильдейца в AddMessage (как в Chatter)
    -- ========================================================================
    local function ChangeGuildName(msgHeader, name, extra, msgCnt, displayName, msgBody)
        local gd = guildInfo[name]
        local suffix = ""
        
        if gd then
            local level = gd.level
            local gp = gd.gp
            
            if level == 80 or level == "80" then level = nil end
            if aoSettings.hideLevel then level = nil end
            if aoSettings.hideGP then gp = nil end
            
            if level and gp then
                suffix = ":" .. level .. ":" .. gp
            elseif gp then
                suffix = ":" .. gp
            elseif level then
                suffix = ":" .. level
            end
        end

        local color = "|cffffffff"
        if gd and gd.classFile and CLASS_COLORS[gd.classFile] then
            color = CLASS_COLORS[gd.classFile]
        end

        local newDisplay = displayName .. suffix
        
        -- ВСЕГДА возвращаем полную строку, даже если suffix пустой!
        return ("|Hplayer:%s%s%s|h%s[%s]|r|h%s"):format(
            name, extra, msgCnt, color, newDisplay, msgBody
        )
    end

    -- ========================================================================
    -- Перехват сообщений
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
                    msg = ReplaceChannelPrefix(msg)
                    
                    -- Подменяем ник гильдейца, если он есть в кэше
                    msg = msg:gsub("(|Hplayer:([^|:]+)([:%d+]*)([^|]*)|h%[([^%]]+)%]|h)(.-)$", ChangeGuildName)
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

        -- Перехват ТОЛЬКО для релея (чтобы отрендерить кастомную строку релея)
        if type(ChatFrame_MessageEventHandler) == "function" then
            local oldMessageHandler = ChatFrame_MessageEventHandler
            ChatFrame_MessageEventHandler = function(self2, event, ...)
                if event == "CHAT_MSG_GUILD" or event == "CHAT_MSG_OFFICER" then
                    local text = select(1, ...)
                    if IsRelayText(text) then
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
    -- Ростер
    -- ========================================================================
    local rosterFrame = CreateFrame("Frame")
    rosterFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
    rosterFrame:RegisterEvent("PLAYER_GUILD_UPDATE")
    rosterFrame:SetScript("OnEvent", function(self, event)
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
    -- Настройки модуля
    -- ========================================================================
    local settingsFrame

    local function OpenAOClickSettings()
        if not settingsFrame then
            local f = CreateFrame("Frame", "NSQC4AOClickSettings", UIParent)
            f:SetSize(380, 220)
            f:SetPoint("CENTER")
            f:SetFrameStrata("DIALOG")
            f:SetBackdrop({
                bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 12,
                insets = { left = 3, right = 3, top = 3, bottom = 3 },
            })
            f:SetBackdropColor(0, 0, 0, 0.9)
            f:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

            local t = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
            t:SetPoint("TOPLEFT", 12, -12)
            t:SetText("Настройки: Ссылки АО")

            local cbLevel = CreateFrame("CheckButton", "NSQC4AOClickHideLevel", f, "UICheckButtonTemplate")
            cbLevel:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -16)
            cbLevel:SetSize(24, 24)
            local l1 = _G[cbLevel:GetName() .. "Text"]
            if l1 then
                l1:SetText("Отключить отображение лвла")
                l1:SetWidth(320)
                l1:SetJustifyH("LEFT")
            end
            cbLevel:SetChecked(aoSettings.hideLevel and true or false)
            cbLevel:SetScript("OnClick", function(self)
                aoSettings.hideLevel = self:GetChecked() and true or false
                print("|cff00ff00[NSQC4]|r AOClick: отображение лвла " ..
                    (aoSettings.hideLevel and "выключено" or "включено"))
            end)

            local cbGP = CreateFrame("CheckButton", "NSQC4AOClickHideGP", f, "UICheckButtonTemplate")
            cbGP:SetPoint("TOPLEFT", cbLevel, "BOTTOMLEFT", 0, -6)
            cbGP:SetSize(24, 24)
            local l2 = _G[cbGP:GetName() .. "Text"]
            if l2 then
                l2:SetText("Отключить отображение ГП")
                l2:SetWidth(320)
                l2:SetJustifyH("LEFT")
            end
            cbGP:SetChecked(aoSettings.hideGP and true or false)
            cbGP:SetScript("OnClick", function(self)
                aoSettings.hideGP = self:GetChecked() and true or false
                print("|cff00ff00[NSQC4]|r AOClick: отображение ГП " ..
                    (aoSettings.hideGP and "выключено" or "включено"))
            end)

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

        local cbLevel = _G["NSQC4AOClickHideLevel"]
        local cbGP    = _G["NSQC4AOClickHideGP"]
        if cbLevel then cbLevel:SetChecked(aoSettings.hideLevel and true or false) end
        if cbGP    then cbGP:SetChecked(aoSettings.hideGP and true or false) end

        settingsFrame:Show()
        settingsFrame:Raise()
    end

    NSQC4.RegisterModuleSettings("ui_ao", OpenAOClickSettings)

    NSQC4.SetModuleMeta("ui_ao", {
        label   = "Ссылки АО",
        tooltip = "Кликабельные ники из канала АО и своей гильдии. ЛКМ — вставить ник, ПКМ — меню.",
        order   = 190,
    })

end)