-- ============================================================================
-- NSQC4 / Quests / NSDB / Clear
-- Одна логика: Clear(scope) — очистить все параметры таблицы.
--   Сама таблица остаётся (пустая).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local NSDB = NSQC4.NSDB
    if not NSDB then return end

    function NSDB:Clear(scope)
        if not self:ValidName(scope) then return false end
        local t = self:Walk(scope)
        if not t then return false end
        for k in pairs(t) do
            t[k] = nil
        end
        return true
    end

end, 250)