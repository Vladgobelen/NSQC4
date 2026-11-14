-- ============================================================================
-- NSQC4 / Quests / Field / Core / Storage / Save
-- Одна логика: self.* → NSDB
--
-- Пишет только. Ничего не читает.
--
-- Сохраняет:
--   x, y           — позиция BOTTOMLEFT (если frame есть)
--   cellSize       — размер клетки (если есть)
--
-- НЕ сохраняет флаги borderVisible/borderless — их пишут
-- SetBorderVisible / SetBorderless в момент изменения.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    local NSDB = NSQC4.NSDB
    if not NSDB then
        print("|cffff0000[NSQC4]|r Storage/Save: NSDB не загружен.")
        return
    end

    local SCOPE = "field"

    function QuestsField:Save()
        -- Геометрия
        if self.frame then
            local x = self.frame:GetLeft()
            local y = self.frame:GetBottom()
            NSDB:Set(SCOPE, "x", x)
            NSDB:Set(SCOPE, "y", y)
        end

        -- Размер клетки
        if self.cellSize then
            NSDB:Set(SCOPE, "cellSize", self.cellSize)
        end

        -- НЕ сохраняем borderless/borderVisible здесь.
        -- См. Border/Visible.lua и Cells/Border.lua.
    end

    -- ========================================================================
    -- Отдельные сеттеры для флагов, которые сами себя сохраняют.
    -- (На случай, если кто-то захочет менять флаг в обход SetBorderVisible.)
    -- ========================================================================
    function QuestsField:SaveFlag(key, value)
        if not key then return end
        NSDB:Set(SCOPE, key, value and true or false)
    end

end, 293)