-- ============================================================================
-- NSQC4 / nowim / ChatHook
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

    -- Функция для подхвата каналов
    local function UpdateChannels()
        for i = 1, 20 do
            local id, name = GetChannelName(i)
            if id and id > 0 and name then
                -- Добавляем канал в список channels, если его там нет
                if not C.db.channels[tostring(id)] then
                    C.db.channels[tostring(id)] = { type = "CHANNEL", name = name }
                end
                -- Включаем его в фильтр по умолчанию, если он не был выключен
                if C.db.settings.filters and C.db.settings.filters[name] == nil then
                    C.db.settings.filters[name] = true
                end
            end
        end
    end

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("CHANNEL_UI_UPDATE")

    frame:SetScript("OnEvent", function(self, event, text, sender)
        if event == "PLAYER_ENTERING_WORLD" or event == "CHANNEL_UI_UPDATE" then
            UpdateChannels()
            return
        end

        if not text or text == "" then return end
        if text:sub(1, 5) == "NSMSG" then return end 

        local E = NSQC4.Nowim.ChatEngine
        if not E then return end

        local chatType = event:match("^CHAT_MSG_(.+)$")
        local targetKey = "GENERAL"
        
        if sender == myName and NSQC4.Nowim._lastSentText == text and (GetTime() - (NSQC4.Nowim._lastSentTime or 0)) < 2 then
            return
        end

        -- Обработка каналов
        if chatType == "CHANNEL" then
            local _, channelName = GetChannelName(text)
            if channelName then
                local filters = C.db.settings.filters or {}
                if filters[channelName] == false then return end -- Фильтр выключен
            end
        end

        -- Системные сообщения
        if chatType == "SYSTEM" or chatType == "LOOT" or chatType == "MONEY" or chatType == "SKILL" or not sender or sender == "" then
            local filters = C.db.settings.filters or {}
            if filters["SYSTEM"] == false then return end
            S.AddMessage("GENERAL", text, false, nil)
        else
            -- Обычные сообщения
            local cleanText = text:gsub("^" .. sender .. ":%s*", "")
            local formattedText = cleanText
            if NSQC4.AOClick_ReplaceAll then
                formattedText = NSQC4.AOClick_ReplaceAll(cleanText)
            end

            if chatType == "WHISPER" then
                targetKey = sender
                E.OpenDialog(targetKey) 
            else
                targetKey = "GENERAL"
            end
            
            local filters = C.db.settings.filters or {}
            if filters[chatType] == false then return end

            S.AddMessage(targetKey, formattedText, false, sender)
        end
        
        if C.db.activeTab == targetKey then
            E.UpdateUI()
        else
            C.db.unread[targetKey] = (C.db.unread[targetKey] or 0) + 1
            local UI = NSQC4.Nowim.UI
            if UI and UI.ChatView and UI.ChatView.Refresh then
                UI.ChatView.Refresh()
            end
            E.UpdateUI()
        end
    end)
end)