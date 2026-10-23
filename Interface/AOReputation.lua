-- ============================================================================
-- NSQC4 / Interface / AOReputation
-- ============================================================================

NSQC4.RegisterModule("ui_ao", function()

    nsDbc4 = nsDbc4 or {}
    nsDbc4.reputation = nsDbc4.reputation or {}

    local P_REQ  = "nsRepReq"
    local P_RESP = "nsRepResp"

    local pending = {}

    function NSQC4.RequestReputation(nick)
        if not nick or nick == "" then return end
        local cleanName = nick:match("^([^%-]+)") or nick

        if nsDbc4.reputation[cleanName] ~= nil then return end
        if pending[cleanName] then return end

        pending[cleanName] = true
        SendAddonMessage(P_REQ, cleanName, "GUILD")
    end

    -- Приём ответа
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

    -- Слежка за чатом (через ChatCatcher)
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

        -- "ник: отношение с гильдией -320/-1000"  (минус сохраняем)
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
    -- Хук на AddMessage: ловим ники в любом сообщении и запрашиваем репутацию
    -- ========================================================================
    for i = 1, NUM_CHAT_WINDOWS do
        local cf = _G["ChatFrame"..i]
        if cf then
            local old = cf.AddMessage
            cf.AddMessage = function(self2, msg, ...)
                if msg and type(msg) == "string" then
                    for nick in msg:gmatch("|Hplayer:([^|]+)|h") do
                        local cleanName = nick:match("^([^%-]+)") or nick
                        if NSQC4.RequestReputation and nsDbc4.reputation[cleanName] == nil then
                            NSQC4.RequestReputation(cleanName)
                        end
                    end
                end
                return old(self2, msg, ...)
            end
        end
    end
    if DEFAULT_CHAT_FRAME then
        local old = DEFAULT_CHAT_FRAME.AddMessage
        DEFAULT_CHAT_FRAME.AddMessage = function(self2, msg, ...)
            if msg and type(msg) == "string" then
                for nick in msg:gmatch("|Hplayer:([^|]+)|h") do
                    local cleanName = nick:match("^([^%-]+)") or nick
                    if NSQC4.RequestReputation and nsDbc4.reputation[cleanName] == nil then
                        NSQC4.RequestReputation(cleanName)
                    end
                end
            end
            return old(self2, msg, ...)
        end
    end

    -- Запрос при входе в мир
    local initFrame = CreateFrame("Frame")
    initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    initFrame:SetScript("OnEvent", function(self)
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        if IsInGuild() then
            NSQC4.RequestReputation(UnitName("player"))
        end
    end)

end)