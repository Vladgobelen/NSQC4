-- ============================================================================
-- NSQC4 / Quests / Field / Init
-- Одна логика: создание класса QuestsFieldClass + экземпляра NSQC4.Field.
-- Никаких вызовов методов и никаких слэшей — это делает Bootstrap.lua.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.Class()
    NSQC4.QuestsFieldClass = QuestsField

    function QuestsField:Init()
        self.frame         = nil
        self.cells         = {}
        self.cellSize      = nil
        self.saved         = nil
        self.borderless    = false
        self.borderVisible = true
        self.backdrop      = nil
        self.closeBtn      = nil
        self.resizeHandle  = nil
        self.floorUpBtn    = nil
        self.floorDownBtn  = nil
        self.onFloorUp     = nil
        self.onFloorDown   = nil
    end

    NSQC4.Field = QuestsField.new()

end, 280)