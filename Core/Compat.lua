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