-- ============================================================================
-- NSQC4 / Quests / Field / Cells / Border
-- Одна логика: включение/выключение линий сетки.
--
--   SetBorderless(v)  -- true → линий нет (Hide), gap = -1
--                     -- false → линии есть (Show), gap = 0
--   IsBorderless()    -- true | false
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    function QuestsField:IsBorderless()
        return self.borderless and true or false
    end

    function QuestsField:SetBorderless(v)
        self.borderless = v and true or false

        local lines = self.gridLines
        if lines then
            local show = not self.borderless
            for _, tex in ipairs(lines.v) do
                if show then tex:Show() else tex:Hide() end
            end
            for _, tex in ipairs(lines.h) do
                if show then tex:Show() else tex:Hide() end
            end
        end

        -- gap -1 при borderless — линии не видны, клетки «слипаются»
        if self.frame and self.ReflowCells then
            self:ReflowCells()
        end

        self:Save()
    end

end, 340)