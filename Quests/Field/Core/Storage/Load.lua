-- ============================================================================
-- NSQC4 / Quests / Field / Core / Storage / Load
-- Одна логика: NSDB → self.saved + self.*
--
-- Читает только. Ничего не пишет.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    local NSDB = NSQC4.NSDB
    if not NSDB then
        print("|cffff0000[NSQC4]|r Storage/Load: NSDB не загружен.")
        return
    end

    local SCOPE = "field"

    function QuestsField:Load()
        -- borderVisible: default = true
        local borderVisible = NSDB:Get(SCOPE, "borderVisible")
        if borderVisible == nil then
            borderVisible = self:GetDefault("borderVisible")
        else
            borderVisible = borderVisible and true or false
        end

        -- borderless: default = false
        local borderless = NSDB:Get(SCOPE, "borderless")
        if borderless == nil then
            borderless = self:GetDefault("borderless")
        else
            borderless = borderless and true or false
        end

        self.saved = {
            x             = NSDB:Get(SCOPE, "x"),
            y             = NSDB:Get(SCOPE, "y"),
            cellSize      = NSDB:Get(SCOPE, "cellSize"),
            borderless    = borderless,
            borderVisible = borderVisible,
        }

        self.borderless    = self.saved.borderless
        self.borderVisible = self.saved.borderVisible

        return self.saved
    end

end, 292)