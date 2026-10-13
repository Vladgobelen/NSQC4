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

    local aoNames = {}

    local function BuildReplacement(letter, code, nick, meta)
        local cleanName = nick:gsub(":+$", "")
        local color = CLASS_COLORS[code] or DEFAULT_COLOR
        aoNames[cleanName] = true

        local nickDisplay = cleanName
        if meta and meta ~= "" then
            nickDisplay = cleanName .. meta
        end

        return "[" .. letter .. "] |Hplayer:" .. cleanName .. "|h" ..
            color .. "[" .. nickDisplay .. "]" .. NICK_COLOR_RESET .. "|h: "
    end

    local function ReplaceAll(msg)
        -- [А2:70:1196] Ник: (уровень + репутация)
        msg = msg:gsub(
            "%[\208\144(%d):(%-?%d+):(%-?%d+)%] (%S+): ",
            function(code, level, rep, nick)
                if tonumber(level) == 80 then
                    return BuildReplacement("А", code, nick, ":" .. rep)
                else
                    return BuildReplacement("А", code, nick, ":" .. level .. ":" .. rep)
                end
            end)
        msg = msg:gsub(
            "%[\208\158(%d):(%-?%d+):(%-?%d+)%] (%S+): ",
            function(code, level, rep, nick)
                if tonumber(level) == 80 then
                    return BuildReplacement("О", code, nick, ":" .. rep)
                else
                    return BuildReplacement("О", code, nick, ":" .. level .. ":" .. rep)
                end
            end)

        -- [А2:1196] Ник: (только репутация, уровень 80)
        msg = msg:gsub(
            "%[\208\144(%d):(%-?%d+)%] (%S+): ",
            function(code, rep, nick)
                return BuildReplacement("А", code, nick, ":" .. rep)
            end)
        msg = msg:gsub(
            "%[\208\158(%d):(%-?%d+)%] (%S+): ",
            function(code, rep, nick)
                return BuildReplacement("О", code, nick, ":" .. rep)
            end)

        -- Fallback: [А2] Ник:
        msg = msg:gsub(
            "%[\208\144(%d)%] (%S+): ",
            function(code, nick) return BuildReplacement("А", code, nick) end)
        msg = msg:gsub(
            "%[\208\158(%d)%] (%S+): ",
            function(code, nick) return BuildReplacement("О", code, nick) end)

        -- Слияние [G] ... [А] → [GА]
        msg = msg:gsub("%[G%].-%[А%]", "[GА]")
        msg = msg:gsub("%[G%].-%[О%]", "[GО]")
        msg = msg:gsub("%[O%].-%[А%]", "[OА]")
        msg = msg:gsub("%[O%].-%[О%]", "[OО]")
        msg = msg:gsub("%[Гильдия%].-%[А%]", "[ГА]")
        msg = msg:gsub("%[Гильдия%].-%[О%]", "[ГО]")
        msg = msg:gsub("%[Офицер%].-%[А%]", "[ОА]")
        msg = msg:gsub("%[Офицер%].-%[О%]", "[ОО]")

        return msg
    end

    local f2 = CreateFrame("Frame")
    f2:RegisterEvent("CHAT_MSG_ADDON")
    f2:SetScript("OnEvent", function(_, _, prefix, text, channel, sender)
        if prefix ~= "nsInfoA" then return end
        if not text or text == "" then return end
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[nsInfo]|r " .. tostring(text))
    end)

    local function HookChatFrame(chatFrame)
        if not chatFrame or chatFrame.hookedAO then return end
        chatFrame.hookedAO = true
        local oldAddMessage = chatFrame.AddMessage
        chatFrame.AddMessage = function(self, msg, ...)
            if msg and type(msg) == "string" then
                msg = ReplaceAll(msg)
            end
            return oldAddMessage(self, msg, ...)
        end
    end

    for i = 1, NUM_CHAT_WINDOWS do
        HookChatFrame(_G["ChatFrame"..i])
    end

    local function ProcessChatFrame(chatFrame)
        if not chatFrame or not chatFrame:IsShown() then return end
        local regions = { chatFrame:GetRegions() }
        for _, region in ipairs(regions) do
            if region.GetText and region:GetObjectType() == "FontString" then
                local text = region:GetText()
                if text and text ~= "" then
                    if text:find("%[G%]") or text:find("%[O%]")
                       or text:find("Гильдия") or text:find("Офицер")
                       or text:find("\208\144%d") or text:find("\208\158%d") then
                        local newText = ReplaceAll(text)
                        if newText ~= text then
                            region:SetText(newText)
                        end
                    end
                end
            end
        end
    end

    local autoRefresh = CreateFrame("Frame")
    autoRefresh:SetScript("OnUpdate", function(self, elapsed)
        self.timer = (self.timer or 0) + elapsed
        if self.timer < 0.5 then return end
        self.timer = 0
        for i = 1, NUM_CHAT_WINDOWS do
            ProcessChatFrame(_G["ChatFrame" .. i])
        end
    end)

    local oldOnHyperlinkShow = ChatFrame_OnHyperlinkShow
    ChatFrame_OnHyperlinkShow = function(self, link, text, button)
        local linkType, linkData = link:match("^(%a+):(.+)$")
        if linkType == "player" and linkData then
            local name = linkData:match("^([^:]+)")
            if name and aoNames[name] then
                if button == "RightButton" then
                    SendAddonMessage(PREFIX_Q, name, "GUILD")
                    return
                elseif button == "LeftButton" then
                    local editBox = self.editBox or ChatFrame1EditBox
                    if editBox then
                        if not editBox:IsShown() then editBox:Show() end
                        editBox:Insert(name .. ", ")
                        editBox:SetFocus()
                    end
                    return
                end
            end
        end
        return oldOnHyperlinkShow(self, link, text, button)
    end

end)