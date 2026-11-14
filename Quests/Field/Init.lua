-- ============================================================================
-- NSQC4 / Quests / Field / Init
-- Одна логика: создание класса QuestsFieldClass.
-- НЕ создаёт экземпляр — это делает Core/Instance/Create.lua.
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

end, 280)