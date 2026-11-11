-- ============================================================================
-- NSQC4 / Quests / NSDB / Set
-- Одна логика: Set(scope, key, value) — записать параметр.
--
--   scope — путь таблицы ("field", "field.pos")
--   key   — имя параметра ("x", "cellSize")
--   value = nil → Delete(scope, key).
--   Таблица по пути scope создаётся, если нет.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local NSDB = NSQC4.NSDB
    if not NSDB then return end

    function NSDB:Set(scope, key, value)
        if not self:ValidName(scope) then return false end
        if key == nil then return false end

        local t = self:WalkCreate(scope)
        if not t then return false end

        if value == nil then
            t[key] = nil
        else
            t[key] = value
        end
        return true
    end

end, 200)