-- ============================================================================
-- NSQC4 / Quests / NSDB / Has
-- Одна логика: Has(scope, key) → true | false.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local NSDB = NSQC4.NSDB
    if not NSDB then return end

    function NSDB:Has(scope, key)
        if not self:ValidName(scope) then return false end
        if key == nil then return false end

        local t = self:Walk(scope)
        if not t then return false end
        return t[key] ~= nil
    end

end, 210)