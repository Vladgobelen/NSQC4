-- ============================================================================
-- NSQC4 / Quests / NSDB / Root
-- Одна логика: корень базы (nsDbc4.quests) + навигация по пути scope.
--
--   Root()              -- nsDbc4.quests (гарантирует)
--   Walk(scope)         -- таблица по пути, БЕЗ создания промежуточных
--   WalkCreate(scope)   -- таблица по пути, С созданием промежуточных
--
-- scope = "field.pos" → nsDbc4.quests.field.pos
-- scope = "field"     → nsDbc4.quests.field
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local NSDB = NSQC4.NSDB
    if not NSDB then return end

    function NSDB:Root()
        nsDbc4 = nsDbc4 or {}
        nsDbc4.quests = nsDbc4.quests or {}
        return nsDbc4.quests
    end

    -- Walk(scope) → таблица | nil (не создаёт).
    function NSDB:Walk(scope)
        if type(scope) ~= "string" or scope == "" then return nil end
        local cur = self:Root()
        for part in scope:gmatch("[^%.]+") do
            cur = cur[part]
            if cur == nil then return nil end
            if type(cur) ~= "table" then return nil end
        end
        return cur
    end

    -- WalkCreate(scope) → таблица (создаёт промежуточные).
    function NSDB:WalkCreate(scope)
        if type(scope) ~= "string" or scope == "" then return nil end
        local cur = self:Root()
        for part in scope:gmatch("[^%.]+") do
            if type(cur[part]) ~= "table" then
                cur[part] = {}
            end
            cur = cur[part]
        end
        return cur
    end

end, 180)