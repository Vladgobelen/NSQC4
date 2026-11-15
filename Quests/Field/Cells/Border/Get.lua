-- ============================================================================
-- NSQC4 / Quests / Field / Cells / Border / Get
-- Одна логика: чтение состояния "borderless" (есть линии или нет).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    function QuestsField:IsBorderless()
        return self.borderless and true or false
    end

end, 341)