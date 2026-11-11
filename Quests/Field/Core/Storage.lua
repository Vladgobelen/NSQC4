-- ============================================================================
-- NSQC4 / Quests / Field / Core / Storage
-- Одна логика: сохранение/загрузка состояния поля через NSDB.
--
--   QuestsField:Load()  -- NSDB:Get("field", ...) → self.saved + self.*
--   QuestsField:Save()  -- self.* → NSDB:Set("field", ...)
--
-- Таблица NSDB: "field".
-- Параметры:
--   x, y           — координаты BOTTOMLEFT (координаты поля)
--   cellSize       — размер клетки в px
--   borderless     — true | false (бордеры клеток)
--   borderVisible  — true | false (подложка: alpha 1 vs 0.01)
--
-- Никаких прямых обращений к nsDbc4 — только NSDB.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    local NSDB = NSQC4.NSDB
    if not NSDB then
        print("|cffff0000[NSQC4]|r Core/Storage: NSDB не загружен.")
        return
    end

    local SCOPE = "field"

    -- ========================================================================
    -- Load — NSDB → self.saved + self.*
    -- ========================================================================
    function QuestsField:Load()
        local borderVisible = NSDB:Get(SCOPE, "borderVisible")
        if borderVisible == nil then
            borderVisible = true          -- подложка видима по умолчанию
        else
            borderVisible = borderVisible and true or false
        end

        self.saved = {
            x             = NSDB:Get(SCOPE, "x"),
            y             = NSDB:Get(SCOPE, "y"),
            cellSize      = NSDB:Get(SCOPE, "cellSize"),
            borderless    = NSDB:Get(SCOPE, "borderless") and true or false,
            borderVisible = borderVisible,
        }

        self.borderless    = self.saved.borderless
        self.borderVisible = self.saved.borderVisible

        return self.saved
    end

    -- ========================================================================
    -- Save — self.* → NSDB
    -- ========================================================================
    function QuestsField:Save()
        if self.frame then
            NSDB:Set(SCOPE, "x", self.frame:GetLeft())
            NSDB:Set(SCOPE, "y", self.frame:GetBottom())
        end

        if self.cellSize then
            NSDB:Set(SCOPE, "cellSize", self.cellSize)
        end

        NSDB:Set(SCOPE, "borderless",    self.borderless and true or false)
        NSDB:Set(SCOPE, "borderVisible", self.borderVisible and true or false)
    end

end, 290)