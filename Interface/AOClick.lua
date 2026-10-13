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

    local function BuildReplacement(letter, code, nick)
        local cleanName = nick:gsub(":+$", "")
        local color = CLASS_COLORS[code] or DEFAULT_COLOR
        aoNames[cleanName] = true
        return "[" .. letter .. "] |Hplayer:" .. cleanName .. "|h" ..
            color .. "[" .. cleanName .. "]" .. NICK_COLOR_RESET .. "|h: "
    end

    local function ReplaceAll(msg)
        msg = msg:gsub(
            "|Hplayer:[^|]+|h%[[^%]]+%]|h: %[\208\144(%d)%] (%S+): ",
            function(code, nick) return BuildReplacement("А", code, nick) end)
        msg = msg:gsub(
            "|Hplayer:[^|]+|h%[[^%]]+%]|h: %[\208\158(%d)%] (%S+): ",
            function(code, nick) return BuildReplacement("О", code, nick) end)

        msg = msg:gsub(
            "%[\208\144(%d)%] (%S+): ",
            function(code, nick) return BuildReplacement("А", code, nick) end)
        msg = msg:gsub(
            "%[\208\158(%d)%] (%S+): ",
            function(code, nick) return BuildReplacement("О", code, nick) end)

        return msg
    end

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