-- ============================================================================
-- NSQC4 / Interface / AOReputation
-- ============================================================================

NSQC4.RegisterModule("ui_ao", function()

    nsDbc4 = nsDbc4 or {}
    nsDbc4.reputation = nsDbc4.reputation or {}

    local P_REQ  = "nsRepReq"
    local P_RESP = "nsRepResp"

    -- Сколько ждать между отправками (сек)
    local SEND_INTERVAL = 0.1

    -- pending: ники, по которым запрос уже отправлен/поставлен в очередь
    local pending = {}

    -- ========================================================================
    -- Единая функция отправки: очередь + таймер
    -- ========================================================================
    local sendQueue  = {}    -- массив ников (FIFO)
    local queuedSet  = {}    -- set: ник уже в очереди (защита от дублей)
    local senderFrame = CreateFrame("Frame")
    local senderOn = false

    local function SendNext()
        local nick = table.remove(sendQueue, 1)
        if not nick then
            if senderOn then
                senderFrame:SetScript("OnUpdate", nil)
                senderOn = false
            end
            return
        end
        queuedSet[nick] = nil

        -- Ещё раз проверяем гильдию — вдруг вышли, пока стояли в очереди
        if not IsInGuild() then
            -- не отправляем; и pending не держим, чтобы при повторном
            -- входе/присоединении к гильдии можно было запросить снова
            pending[nick] = nil
            return
        end

        SendAddonMessage(P_REQ, nick, "GUILD")
    end

    local function StartSender()
        if senderOn then return end
        senderOn = true
        senderFrame:SetScript("OnUpdate", function(_, elapsed)
            -- аккуратно: считаем накопленное время, чтобы 0.1с были честными
            senderFrame._acc = (senderFrame._acc or 0) + elapsed
            if senderFrame._acc < SEND_INTERVAL then return end
            senderFrame._acc = 0
            SendNext()
        end)
    end

    local function EnqueueRequest(nick)
        if not nick or nick == "" then return end
        local cleanName = nick:match("^([^%-]+)") or nick

        if not IsInGuild() then return end              -- не в гильдии — не шлём
        if nsDbc4.reputation[cleanName] ~= nil then return end
        if pending[cleanName] then return end
        if queuedSet[cleanName] then return end

        pending[cleanName] = true
        queuedSet[cleanName] = true
        sendQueue[#sendQueue + 1] = cleanName

        StartSender()
    end

    -- Публичная единая точка отправки (все модули — только сюда)
    NSQC4.SendReputationRequest = EnqueueRequest

    -- Совместимость со старым именем
    function NSQC4.RequestReputation(nick)
        EnqueueRequest(nick)
    end

    -- ========================================================================
    -- Приём ответа
    -- ========================================================================
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
        if prefix ~= P_RESP then return end

        local nick, repStr = message:match("^([^|]+)|(%-?%d+)$")
        if nick and repStr then
            local cleanName = nick:match("^([^%-]+)") or nick
            nsDbc4.reputation[cleanName] = tonumber(repStr) or 0
            pending[cleanName] = nil
        end
    end)

    -- ========================================================================
    -- Слежка за чатом (через ChatCatcher)
    -- ========================================================================
    local function HandleReputationUpdate(words, sender, text, channel, prefix)
        if not text or text == "" then return end

        -- "ник: репутация N >> M"
        local nick, newRep = text:match("([^%s:]+): репутация %-?%d+%s*>>%s*(%-?%d+)")
        if nick and newRep then
            local cleanName = nick:match("^([^%-]+)") or nick
            nsDbc4.reputation[cleanName] = tonumber(newRep) or 0
            pending[cleanName] = nil
            return
        end

        -- "ник: отношение с гильдией -320/-1000" (минус сохраняем)
        local nick2, newRep2 = text:match("([^%s:]+): отношение с гильдией (%-?%d+)")
        if nick2 and newRep2 then
            local cleanName = nick2:match("^([^%-]+)") or nick2
            nsDbc4.reputation[cleanName] = tonumber(newRep2) or 0
            pending[cleanName] = nil
        end
    end

    if NSQC4.ChatCatcher then
        NSQC4.ChatCatcher:Register(HandleReputationUpdate, "ao_reputation")
    end

    -- ========================================================================
    -- Хук на AddMessage: ловим ники и ставим в очередь запросов
    -- ========================================================================
    local function HookAddMessage(cf)
        if not cf then return end
        local old = cf.AddMessage
        cf.AddMessage = function(self2, msg, ...)
            if msg and type(msg) == "string" then
                -- [^|:]+ — отсекает и |, и :0:0 / :12:34
                for nick in msg:gmatch("|Hplayer:([^|:]+)|h") do
                    if nsDbc4.reputation[nick] == nil then
                        EnqueueRequest(nick)
                    end
                end
            end
            return old(self2, msg, ...)
        end
    end

    for i = 1, NUM_CHAT_WINDOWS do
        HookAddMessage(_G["ChatFrame"..i])
    end
    if DEFAULT_CHAT_FRAME then
        HookAddMessage(DEFAULT_CHAT_FRAME)
    end

    -- ========================================================================
    -- Запрос при входе в мир (только если в гильдии)
    -- ========================================================================
    local initFrame = CreateFrame("Frame")
    initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    initFrame:SetScript("OnEvent", function(self)
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        if IsInGuild() then
            EnqueueRequest(UnitName("player"))
        end
    end)

end)