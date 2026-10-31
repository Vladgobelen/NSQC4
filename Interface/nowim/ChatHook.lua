-- ============================================================================
-- NSQC4 / nowim / ChatHook (ФИКС ОФИЦЕРСКОГО)
-- ============================================================================

NSQC4.RegisterModule("nowim", function()

    local S = NSQC4.Nowim.Storage
    local C = NSQC4.Nowim.Config
    local myName = UnitName("player")

    local frame = CreateFrame("Frame")
    
    frame:RegisterEvent("CHAT_MSG_GUILD")
    frame:RegisterEvent("CHAT_MSG_OFFICER")
    frame:RegisterEvent("CHAT_MSG_RAID")
    frame:RegisterEvent("CHAT_MSG_RAID_LEADER")
    frame:RegisterEvent("CHAT_MSG_WHISPER")
    frame:RegisterEvent("CHAT_MSG_SAY")
    frame:RegisterEvent("CHAT_MSG_YELL")
    frame:RegisterEvent("CHAT_MSG_PARTY")
    frame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
    frame:RegisterEvent("CHAT_MSG_CHANNEL")
    frame:RegisterEvent("CHAT_MSG_SYSTEM")
    frame:RegisterEvent("CHAT_MSG_RAID_WARNING")
    frame:RegisterEvent("CHAT_MSG_MONSTER_SAY")
    frame:RegisterEvent("CHAT_MSG_MONSTER_YELL")
    frame:RegisterEvent("CHAT_MSG_MONSTER_EMOTE")
    frame:RegisterEvent("CHAT_MSG_BATTLEGROUND")
    frame:RegisterEvent("CHAT_MSG_BATTLEGROUND_LEADER")
    frame:RegisterEvent("CHAT_MSG_EMOTE")
    frame:RegisterEvent("CHAT_MSG_LOOT")
    frame:RegisterEvent("CHAT_MSG_MONEY")
    frame:RegisterEvent("CHAT_MSG_SKILL")

    frame:SetScript("OnEvent", function(self, event, text, sender)
        if not text or text == "" then return end
        if text:sub(1, 5) == "NSMSG" then return end 

        local E = NSQC4.Nowim.ChatEngine
        if not E then return end

        local chatType = event:match("^CHAT_MSG_(.+)$")
        local targetKey = "GENERAL"
        local isMine = (sender == myName)

        local isAO = text:find("^%[O") or text:find("^%[A") or text:find("^%[О") or text:find("^%[А") or text:find("^|c%x%x%x%x%x%x%[O") or text:find("^|c%x%x%x%x%x%x%[A")

        local charTag
        if isAO then
            isMine = false
            charTag = nil
            if sender and sender ~= "" then
                text = text:gsub("^" .. sender .. ":%s*", "")
            end
        else
            charTag = isMine and myName or sender
        end

        if isMine and NSQC4.Nowim._lastSentText == text and (GetTime() - (NSQC4.Nowim._lastSentTime or 0)) < 2 then
            return
        end

        if chatType == "CHANNEL" then
            local _, channelName = GetChannelName(text)
            if channelName then
                local filters = C.db.settings.filters or {}
                if filters[channelName] == false then return end
            end
        end

        local formattedText = text

        if chatType == "SYSTEM" or chatType == "LOOT" or chatType == "MONEY" or chatType == "SKILL" or not sender or sender == "" then
            local filters = C.db.settings.filters or {}
            if filters["SYSTEM"] == false then return end
            S.AddMessage("GENERAL", formattedText, false, nil, chatType)
        else
            if chatType == "OFFICER" then
                S.AddMessage("OFFICER", formattedText, isMine, charTag, chatType)
                
                if C.db.settings.showOfficerInGuild then
                    S.AddMessage("GUILD", formattedText, isMine, charTag, chatType)
                end
                
                local hasOfficerTab = false
                for _, key in ipairs(C.db.openTabs) do
                    if key == "OFFICER" then hasOfficerTab = true break end
                end
                if not hasOfficerTab then
                    E.OpenDialog("OFFICER", true)
                end
                
                local UI = NSQC4.Nowim.UI
                if UI and UI.Chat and UI.Chat.Refresh then UI.Chat.Refresh() end
                
                E.UpdateUI()
                return
            end

            if chatType == "WHISPER" then
                targetKey = sender
                E.OpenDialog(targetKey, true) 
            elseif chatType == "GUILD" then
                targetKey = "GUILD"
                S.AddMessage("GUILD", formattedText, isMine, charTag, chatType)
                S.AddMessage("GENERAL", formattedText, isMine, charTag, chatType)
            else
                targetKey = "GENERAL"
            end
            
            local filters = C.db.settings.filters or {}
            if filters[chatType] == false then return end

            if chatType ~= "GUILD" then
                S.AddMessage(targetKey, formattedText, isMine, charTag, chatType)
            end
            
            if C.db.activeTab == targetKey then
                local UI = NSQC4.Nowim.UI
                if UI and UI.Chat and UI.Chat.Refresh then UI.Chat.Refresh() end
            end
        end
        
        if C.db.activeTab == targetKey then
            E.UpdateUI()
        else
            C.db.unread[targetKey] = (C.db.unread[targetKey] or 0) + 1
            local UI = NSQC4.Nowim.UI
            if UI and UI.Chat and UI.Chat.Refresh then
                UI.Chat.Refresh()
            end
            E.UpdateUI()
        end
    end)
end)