-- ============================================================================
-- NSQC4 / Quests / Field / Bootstrap / Slash
-- Одна логика: регистрация слэш-команды /ns_field.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    SLASH_NSFIELD1 = "/ns_field"
    SlashCmdList["NSFIELD"] = function()
        local f = NSQC4.Field
        if f and f.Toggle then
            f:Toggle()
        end
    end

end, 621)