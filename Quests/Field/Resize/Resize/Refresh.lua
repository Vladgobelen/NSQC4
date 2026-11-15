-- ============================================================================
-- NSQC4 / Quests / Field / Resize / Resize / Refresh
-- Одна логика: оркестрация изменения размера.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    function QuestsField:Resize(cs)
        local changed = self:SetCellSize(cs)
        if not changed then
            -- Размер не изменился — но всё равно вернём true (успех)
            -- или false? Для совместимости вернём true, если cellSize валиден.
            -- Но если cellSize невалиден, SetCellSize вернёт false.
            return self.cellSize ~= nil
        end

        self:ApplyNewSize()
        self:Save()
        return true
    end

end, 403)