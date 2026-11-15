-- ============================================================================
-- NSQC4 / Quests / Field / Resize / Resize / Size
-- Одна логика: применение нового cellSize к frame (только геометрия).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    local CONST       = NSQC4.QuestsFieldConst
    if not QuestsField or not CONST then return end

    local MIN_CELL = CONST.MIN_CELL

    -- Устанавливает cellSize и меняет размер frame.
    -- Возвращает true, если размер реально изменился.
    function QuestsField:SetCellSize(cs)
        cs = tonumber(cs)
        if not cs then return false end

        local effMax = self:MaxCellForScreen()
        if cs < MIN_CELL then cs = MIN_CELL end
        if cs > effMax then cs = effMax end
        cs = math.floor(cs + 0.5)

        if cs == self.cellSize then return false end

        self.cellSize = cs

        if self.frame and self._FrameSizeForCell then
            local w, h = self._FrameSizeForCell(cs)
            self.frame:SetSize(w, h)
        end

        return true
    end

end, 401)