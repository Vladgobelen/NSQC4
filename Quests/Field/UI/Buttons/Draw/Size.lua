-- ============================================================================
-- NSQC4 / Quests / Field / UI / Buttons / Draw / Size
-- Одна логика: установка размера кнопки.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    local SIZE = 32

    -- Размер кнопки (минимум из cellSize и 32)
    function QuestsField:GetButtonSize()
        local cs = self.cellSize or SIZE
        if cs < SIZE then return cs end
        return SIZE
    end

    -- Применяет размер, если кнопка не нажата
    function QuestsField:ApplyButtonSize(rec)
        if self:IsPressed(rec.texture) then return end
        local bs = self:GetButtonSize()
        rec.texture:SetSize(bs, bs)
    end

end, 464)