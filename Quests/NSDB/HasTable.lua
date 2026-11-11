-- ============================================================================
-- NSQC4 / Quests / NSDB / HasTable
-- Одна логика: HasTable(scope) → true | false.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local NSDB = NSQC4.NSDB
    if not NSDB then return end

    function NSDB:HasTable(scope)
        if not self:ValidName(scope) then return false end
        return self:Walk(scope) ~= nil
    end

end, 220)