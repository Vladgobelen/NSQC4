-- ============================================================================
-- NSQC4 / Quests / Field / Resize / Resize / Apply
-- Одна логика: перерисовка всех элементов под новый размер.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    function QuestsField:ApplyNewSize()
        -- 1. Сетка
        if self.ReflowCells then self:ReflowCells() end

        -- 2. Кнопки панелей
        if self.RefreshAllButtons then self:RefreshAllButtons() end

        -- 3. Свитчеры
        if self.RefreshSwitchers then self:RefreshSwitchers() end

        -- 4. Якоря подложки (если есть)
        if self.ApplyBorderAnchors then self:ApplyBorderAnchors() end
    end

end, 402)