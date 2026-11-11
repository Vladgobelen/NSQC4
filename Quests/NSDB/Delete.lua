-- ============================================================================
-- NSQC4 / Quests / NSDB / Delete
-- Одна логика: Delete(scope, key) → true | false.
--   true, если ключ был и удалён.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local NSDB = NSQC4.NSDB
    if not NSDB then return end

    function NSDB:Delete(scope, key)
        if not self:ValidName(scope) then return false end
        if key == nil then return false end

        local t = self:Walk(scope)
        if not t then return false end
        if t[key] == nil then return false end
        t[key] = nil
        return true
    end

end, 240)