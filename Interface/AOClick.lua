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

    -- Дабл-клик — состояние
    local lastClickTime   = 0
    local lastClickButton = nil
    local lastClickName   = nil
    local clickPending    = false

    local ClickTimerFrame = CreateFrame("Frame")
    ClickTimerFrame:Hide()
    ClickTimerFrame.elapsed = 0
    ClickTimerFrame:SetScript("OnUpdate", function(self, elapsed)
        if not clickPending then return end
        self.elapsed = self.elapsed + elapsed
        if self.elapsed >= 0.3 then
            self.elapsed = 0
            self:Hide()
            clickPending = false

            local button = lastClickButton
            local name = lastClickName

            if not (name and aoNames[name]) then return end

            if button == "RightButton" then
                SendAddonMessage(PREFIX_Q, name, "GUILD")
            elseif button == "LeftButton" then
                local editBox = ChatFrame1EditBox
                if editBox then
                    if not editBox:IsShown() then editBox:Show() end
                    editBox:Insert(name .. ", ")
                    editBox:SetFocus()
                end
            end
        end
    end)

    -- Собираем две ссылки:
    --   |Hchannel:GUILD|h[G]|h        → клик по [G] откроет /g
    --   |Hplayer:Ашвин|h[Ашвин:8:0]|h → клик по нику — наша логика
    -- Между ними — буква фракции без пробелов.
    local function BuildReplacement(letter, code, nick, meta)
        local cleanName = nick:gsub(":+$", "")
        local color = CLASS_COLORS[code] or DEFAULT_COLOR
        aoNames[cleanName] = true

        local nickDisplay = cleanName
        if meta and meta ~= "" then
            nickDisplay = cleanName .. meta
        end

        local channelLink = "|Hchannel:GUILD|h[G]|h"
        local nickLink = "|Hplayer:" .. cleanName .. "|h" ..
            color .. "[" .. nickDisplay .. "]" .. NICK_COLOR_RESET .. "|h"

        return channelLink .. letter .. nickLink .. ": "
    end

    -- Поглощаем префикс ядра: "|Hplayer:ОТПР|h[ОТПР]|h: " вместе с "[О0:8:0] Ник:"
    local function ReplaceAll(msg)
        -- 3 числа
        msg = msg:gsub(
            "|Hplayer:[^|]+|h%[[^%]]+%]|h: %[\208\144(%d):(%-?%d+):(%-?%d+)%] (%S+): ",
            function(code, level, rep, nick)
                if tonumber(level) == 80 then
                    return BuildReplacement("А", code, nick, ":" .. rep)
                else
                    return BuildReplacement("А", code, nick, ":" .. level .. ":" .. rep)
                end
            end)
        msg = msg:gsub(
            "|Hplayer:[^|]+|h%[[^%]]+%]|h: %[\208\158(%d):(%-?%d+):(%-?%d+)%] (%S+): ",
            function(code, level, rep, nick)
                if tonumber(level) == 80 then
                    return BuildReplacement("О", code, nick, ":" .. rep)
                else
                    return BuildReplacement("О", code, nick, ":" .. level .. ":" .. rep)
                end
            end)

        -- 2 числа
        msg = msg:gsub(
            "|Hplayer:[^|]+|h%[[^%]]+%]|h: %[\208\144(%d):(%-?%d+)%] (%S+): ",
            function(code, rep, nick)
                return BuildReplacement("А", code, nick, ":" .. rep)
            end)
        msg = msg:gsub(
            "|Hplayer:[^|]+|h%[[^%]]+%]|h: %[\208\158(%d):(%-?%d+)%] (%S+): ",
            function(code, rep, nick)
                return BuildReplacement("О", code, nick, ":" .. rep)
            end)

        -- 1 число
        msg = msg:gsub(
            "|Hplayer:[^|]+|h%[[^%]]+%]|h: %[\208\144(%d)%] (%S+): ",
            function(code, nick) return BuildReplacement("А", code, nick) end)
        msg = msg:gsub(
            "|Hplayer:[^|]+|h%[[^%]]+%]|h: %[\208\158(%d)%] (%S+): ",
            function(code, nick) return BuildReplacement("О", code, nick) end)

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

    -- Хук 1: [G] → /g.   Хук 2: [Ник:level:rep] → наша логика
    local oldOnHyperlinkShow = ChatFrame_OnHyperlinkShow
    ChatFrame_OnHyperlinkShow = function(self, link, text, button)
        local linkType, linkData = link:match("^(%a+):(.+)$")

        if linkType == "channel" then
            if button == "LeftButton" then
                if linkData == "GUILD" then
                    ChatFrame_OpenChat("/g ", self)
                elseif linkData == "OFFICER" then
                    ChatFrame_OpenChat("/o ", self)
                else
                    ChatFrame_OpenChat("/g ", self)
                end
            end
            return
        end

        if linkType == "player" and linkData then
            local name = linkData:match("^([^:]+)")
            if not (name and aoNames[name]) then
                return oldOnHyperlinkShow(self, link, text, button)
            end

            local now = GetTime()

            if clickPending
                and (now - lastClickTime < 0.3)
                and (button == lastClickButton)
                and (name == lastClickName)
            then
                clickPending = false
                ClickTimerFrame.elapsed = 0
                ClickTimerFrame:Hide()
                return
            else
                clickPending    = true
                lastClickTime   = now
                lastClickButton = button
                lastClickName   = name
                ClickTimerFrame.elapsed = 0
                ClickTimerFrame:Show()
                return
            end
        end

        return oldOnHyperlinkShow(self, link, text, button)
    end

end)