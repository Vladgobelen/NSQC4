-- ============================================================================
-- NSQC4 / Quests / Field / Resize / Resize
-- Одна логика: применить новый cellSize к полю.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    local CONST       = NSQC4.QuestsFieldConst
    if not QuestsField or not CONST then return end

    local MIN_CELL = CONST.MIN_CELL

    function QuestsField:Resize(cs)
        cs = tonumber(cs)
        if not cs then return false end

        local effMax = self:MaxCellForScreen()
        if cs < MIN_CELL then cs = MIN_CELL end
        if cs > effMax then cs = effMax end
        cs = math.floor(cs + 0.5)

        if cs == self.cellSize then return true end

        self.cellSize = cs

        if self.frame and self._FrameSizeForCell then
            local w, h = self._FrameSizeForCell(cs)
            self.frame:SetSize(w, h)
        end

        -- клетки
        if self.ReflowCells then self:ReflowCells() end

        -- кнопки панелей — пересчитать позиции под новый размер frame
        if self.RefreshAllButtons then self:RefreshAllButtons() end

        -- свитчеры — пересчитать позиции
        if self.RefreshSwitchers then self:RefreshSwitchers() end

        if self.ApplyBorderAnchors then self:ApplyBorderAnchors() end

        self:Save()
        return true
    end

end, 400)