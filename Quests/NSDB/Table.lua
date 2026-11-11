-- ============================================================================
-- NSQC4 / Quests / NSDB / Table
-- Одна логика: Table(scope) — создать/получить таблицу по пути scope.
--
--   Table("field")       → nsDbc4.quests.field
--   Table("field.pos")   → nsDbc4.quests.field.pos
--   Создаёт, если нет.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local NSDB = NSQC4.NSDB
    if not NSDB then return end

    function NSDB:Table(scope)
        if not self:ValidName(scope) then return nil end
        return self:WalkCreate(scope)
    end

end, 230)