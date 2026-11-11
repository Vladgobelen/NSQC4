-- ============================================================================
-- NSQC4 / Quests / NSDB / DropTable
-- Одна логика: DropTable(scope) — удалить таблицу по пути.
--
--   DropTable("field")       → nsDbc4.quests.field = nil
--   DropTable("field.pos")   → nsDbc4.quests.field.pos = nil
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local NSDB = NSQC4.NSDB
    if not NSDB then return end

    function NSDB:DropTable(scope)
        if not self:ValidName(scope) then return false end

        -- Разбить на родителя и последний сегмент.
        local parentPath, lastName = scope:match("^(.*)%.([^%.]+)$")
        local parent
        if parentPath then
            parent = self:Walk(parentPath)
        else
            parent = self:Root()
            lastName = scope
        end

        if not parent then return false end
        if parent[lastName] == nil then return false end
        parent[lastName] = nil
        return true
    end

end, 260)