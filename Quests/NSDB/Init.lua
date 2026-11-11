-- ============================================================================
-- NSQC4 / Quests / NSDB / Init
-- Namespace базы данных + общие утилиты (ValidName).
-- Никаких методов хранения — они в отдельных файлах.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local NSDB = {}
    NSQC4.NSDB = NSDB

    function NSDB:ValidName(name)
        return type(name) == "string" and name ~= ""
    end

end, 170)