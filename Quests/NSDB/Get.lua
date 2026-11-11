-- ============================================================================
-- NSQC4 / Quests / NSDB / Get
-- Одна логика: Get(scope, key) → value | nil.
--   Таблицы/ключа нет — nil (без ошибки).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local NSDB = NSQC4.NSDB
    if not NSDB then return end

    function NSDB:Get(scope, key)
        if not self:ValidName(scope) then return nil end
        if key == nil then return nil end

        local t = self:Walk(scope)
        if not t then return nil end
        return t[key]
    end

end, 190)