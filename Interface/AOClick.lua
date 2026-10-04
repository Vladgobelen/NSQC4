-- ============================================================================
-- NSQC4 / Interface / AOClick
-- Кликабельные ники из канала АО. Модуль "ui_ao".
-- ============================================================================

NSQC4.RegisterModule("ui_ao", function()

    local DISPLAY_PREFIX = "\208\144O"   -- «АO» в UTF-8
    local NICK_COLOR = "|cFFC0C0C0"
    local NICK_COLOR_RESET = "|r"

    local aoNames = {}

    -- Ретрансляция giveMeInfo из GUILD в RAID
    local f = CreateFrame("Frame")
    f:RegisterEvent("CHAT_MSG_ADDON")
    f:SetScript("OnEvent", function(_, _, prefix, text, channel)
        if prefix == "giveMeInfo" and channel == "GUILD" then
            local nick = text:match("^(%S+)")
            if nick then
                SendAddonMessage("giveMeInfoR", nick, "RAID")
            end
        end
    end)

    -- Хук на AddMessage каждого чат-фрейма
    local function HookChatFrame(chatFrame)
        if not chatFrame or chatFrame.hookedAO then return end
        chatFrame.hookedAO = true

        local oldAddMessage = chatFrame.AddMessage
        chatFrame.AddMessage = function(self, msg, ...)
            if msg and type(msg) == "string" then
                local newMsg = msg:gsub(
                    "|Hplayer:[^|]+|h%[[^%]]+%]|h: " .. DISPLAY_PREFIX .. " (%S+):?%s",
                    function(targetName)
                        local cleanName = targetName:gsub(":+$", "")
                        aoNames[cleanName] = true

                        local clickableLink = "|Hplayer:" .. cleanName .. "|h" ..
                            NICK_COLOR .. "[" .. cleanName .. "]" .. NICK_COLOR_RESET .. "|h"
                        return "[" .. DISPLAY_PREFIX .. "] " .. clickableLink .. " "
                    end
                )
                return oldAddMessage(self, newMsg, ...)
            end
            return oldAddMessage(self, msg, ...)
        end
    end

    for i = 1, NUM_CHAT_WINDOWS do
        HookChatFrame(_G["ChatFrame"..i])
    end

    -- Перехват клика по гиперссылке
    local oldOnHyperlinkShow = ChatFrame_OnHyperlinkShow
    ChatFrame_OnHyperlinkShow = function(self, link, text, button)
        local linkType, linkData = link:match("^(%a+):(.+)$")

        if linkType == "player" and linkData then
            local name = linkData:match("^([^:]+)")

            if name and aoNames[name] then
                if button == "RightButton" then
                    SendAddonMessage("giveMeInfo", name, "GUILD")
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