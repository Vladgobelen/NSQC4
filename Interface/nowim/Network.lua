-- ============================================================================
-- NSQC4 / nowim / Network
-- ============================================================================

NSQC4.RegisterModule("nowim", function()
    local C = NSQC4.Nowim.Config
    local U = NSQC4.Nowim.Utils
    local S = NSQC4.Nowim.Storage

    local N = {}
    NSQC4.Nowim.Network = N

    local sendQueue = {}
    local isSending = false

    local function ProcessQueue()
        if isSending or #sendQueue == 0 then return end
        isSending = true

        local msgData = table.remove(sendQueue, 1)
        local target = msgData.target
        local text = U.TrimToBytes(msgData.text, C.MAX_BYTES)

        local isChannel = C.db.channels[target] ~= nil

        if target == UnitName("player") then
            S.AddMessage(target, text, true, UnitName("player"))
            N.UpdateUI(target)
        elseif isChannel then
            local chatType = C.db.channels[target].type

            NSQC4.Nowim._lastSentText = text
            NSQC4.Nowim._lastSentTime = GetTime()
            NSQC4.Nowim._lastSentTarget = target

            if chatType == "GUILD" or chatType == "RAID" then
                SendChatMessage(text, chatType)
            end

            S.AddMessage(target, text, true, UnitName("player"))
        else
            SendAddonMessage(C.ADDON_PREFIX, string.format("FROM:%s|TEXT:%s", UnitName("player"), text), "WHISPER", target)
            S.AddMessage(target, text, true, UnitName("player"))
        end

        local timer = CreateFrame("Frame")
        local elapsed = 0
        timer:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            if elapsed >= C.SEND_DELAY then
                self:SetScript("OnUpdate", nil)
                isSending = false
                ProcessQueue()
            end
        end)
    end

    function N.QueueMessage(target, text)
        if not target or not text or text == "" then return end
        table.insert(sendQueue, { target = target, text = text })
        ProcessQueue()
    end

    if type(RegisterAddonMessagePrefix) == "function" then
        RegisterAddonMessagePrefix(C.ADDON_PREFIX)
    end

    if NSQC4.ChatHandler and type(NSQC4.ChatHandler.Register) == "function" then
        NSQC4.ChatHandler:Register("ADDON:" .. string.lower(C.ADDON_PREFIX), {
            func = function(words, sender, text, channel, prefix)
                if text:sub(1, 5) == "CHAN:" then
                    local chatType, fromNick, msgText = text:match("^CHAN:([^|]+)|FROM:([^|]+)|TEXT:(.+)$")
                    if chatType and msgText then
                        S.AddMessage(chatType, msgText, false, fromNick)
                        N.UpdateUI(chatType)
                    end
                else
                    local fromNick, msgText = text:match("^FROM:([^|]+)|TEXT:(.+)$")
                    if fromNick and msgText then
                        S.AddMessage(fromNick, msgText, false, fromNick)
                        N.UpdateUI(fromNick)
                        if C.db.settings.playSound and PlaySoundFile then
                            PlaySoundFile("Interface\\AddOns\\NSQC4\\Media\\Sounds\\m.ogg")
                        end
                    end
                end
            end,
            stopOnMatch = true,
        })
    end

    -- ИСПРАВЛЕНО: сравнение с C.db.activeTab, вызов UI.Chat.Refresh
    function N.UpdateUI(target)
        local UI = NSQC4.Nowim.UI
        if not UI then return end
        if C.db.activeTab == target and UI.Chat and UI.Chat.Refresh then
            UI.Chat.Refresh()
        end
    end
end)