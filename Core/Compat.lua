-- ============================================================================
-- NSQC4 / Core / Compat
-- Совместимость: функции, отсутствующие в 3.3.5a.
-- ============================================================================

-- IsInRaid() — нет в 3.3.5a
if not IsInRaid then
    function IsInRaid()
        return UnitInRaid("player") ~= nil
    end
end

-- GetNumGroupMembers() — нет в 3.3.5a
if not GetNumGroupMembers then
    function GetNumGroupMembers()
        local raid = GetNumRaidMembers()
        if raid > 0 then return raid end
        return GetNumPartyMembers() + 1   -- +1 = ты сам
    end
end

-- IsInGroup() — есть, но в 3.3.5a возвращает nil, а не false
if not IsInGroup then
    function IsInGroup()
        return GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0
    end
end