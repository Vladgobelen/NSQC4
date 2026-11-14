-- ============================================================================
-- NSQC4 / Quests / Field / Bootstrap / Diagnostics
-- Одна логика: итоговая диагностика (что создано после инициализации).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local field = NSQC4.Field
    if not field then return end

    -- Итоговое сообщение в чат
    print("|cff00ffff[FIELD]|r Блок 4 загружен (панели). /ns_field")

end, 623)